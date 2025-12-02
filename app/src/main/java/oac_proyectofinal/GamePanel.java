package oac_proyectofinal;

import javax.swing.*;
import java.awt.*;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.LinkedList;

public class GamePanel extends JPanel {
    private int TILE_SIZE = 30;
    private int COLS = 20;
    private int ROWS = 20;
    private int SCREEN_WIDTH;
    private int SCREEN_HEIGHT;

    private Snake snake;
    private Food food;
    private Renderer renderer;
    private GameLoop gameLoop;
    
    private GameNative nativeAPI;
    private ByteBuffer gameStateBuffer;
    private ByteBuffer prevStateBuffer;
    
    private boolean isGameOver = false;
    private int score = 20; 
    private float currentAlpha = 0; 
    private boolean endDialogShown = false;

    public GamePanel() {
        String[] options = {"Pequeño", "Mediano", "Grande"};
        int choice = JOptionPane.showOptionDialog(null, "Selecciona el tamaño del mapa:", "Tamaño del mapa",
                JOptionPane.DEFAULT_OPTION, JOptionPane.QUESTION_MESSAGE, null, options, options[1]);

        switch (choice) {
            case 0: COLS = 15; ROWS = 15; TILE_SIZE = 30; break;
            case 2: COLS = 30; ROWS = 30; TILE_SIZE = 20; break;
            default: COLS = 20; ROWS = 20; TILE_SIZE = 30; break;
        }

        SCREEN_WIDTH = COLS * TILE_SIZE;
        SCREEN_HEIGHT = ROWS * TILE_SIZE;
        this.setPreferredSize(new Dimension(SCREEN_WIDTH, SCREEN_HEIGHT));
        this.setBackground(Color.BLACK);
        this.setFocusable(true);
        this.addKeyListener(new ControlHandler());

        nativeAPI = new GameNative();
        
        gameStateBuffer = ByteBuffer.allocateDirect(2048);
        gameStateBuffer.order(ByteOrder.nativeOrder());
        prevStateBuffer = ByteBuffer.allocateDirect(2048);
        prevStateBuffer.order(ByteOrder.nativeOrder());

        renderer = new Renderer(TILE_SIZE);
        initGame();

        gameLoop = new GameLoop(this);
        gameLoop.start();
    }

    private void initGame() {
        nativeAPI.gameInit(gameStateBuffer, COLS, ROWS);
        prevStateBuffer.clear();
        ByteBuffer tmp = gameStateBuffer.duplicate(); tmp.rewind();
        prevStateBuffer.put(tmp);
        
        snake = new Snake(COLS / 2, ROWS / 2);
        food = new Food(COLS, ROWS, snake); 
        
        score = 20;
        isGameOver = false;
    }

    public void updateGameLogic() {
        if (isGameOver) return;

        try {
            prevStateBuffer.clear();
            ByteBuffer src = gameStateBuffer.duplicate(); src.rewind();
            prevStateBuffer.put(src);
        } catch (Exception ignore) {}

        nativeAPI.gameTick(gameStateBuffer);

        score = nativeAPI.gameGetScore(gameStateBuffer);
        int gameOverStatus = nativeAPI.gameIsGameOver(gameStateBuffer);
        if (gameOverStatus == 1) {
            isGameOver = true;
        }

        LinkedList<Position> prevBody = parseBodyFromBuffer(prevStateBuffer);
        LinkedList<Position> currBody = parseBodyFromBuffer(gameStateBuffer);

        if (currBody.size() > 1 && gameStateBuffer != null) {
            Position head = currBody.getFirst();
            int hx = head.getX();
            int hy = head.getY();
            int len = currBody.size();
            int tailIndex = len - 1;
            int foodX = gameStateBuffer.getInt(24);
            int foodY = gameStateBuffer.getInt(28);
            boolean collided = false;
            for (int i = 1; i < len; i++) {
                Position p = currBody.get(i);
                int px = p.getX();
                int py = p.getY();
                if (px == hx && py == hy) {
                    if (i == tailIndex) {
                        if (px == foodX && py == foodY) {
                            collided = true;
                            break;
                        }
                    } else {
                        collided = true;
                        break;
                    }
                }
            }
            if (collided) {
                try {
                    gameStateBuffer.putInt(12, 1);
                } catch (Exception ignored) {}
                isGameOver = true;
            }
        }

        snake.getPrevBody().clear();
        snake.getPrevBody().addAll(prevBody);
        snake.getBody().clear();
        snake.getBody().addAll(currBody);

        int nativeFoodX = gameStateBuffer.getInt(24);
        int nativeFoodY = gameStateBuffer.getInt(28);
        try {
            food.setPosition(new Position(nativeFoodX, nativeFoodY));
        } catch (NoSuchMethodError | Exception ignored) {
        }

        int nativeLength = 0;
        try { nativeLength = gameStateBuffer.getInt(32); } catch (Exception ignored) {}
        if (nativeLength >= COLS * ROWS) {
            isGameOver = true;
            if (!endDialogShown) handleEnd(true);
            return;
        }

        if (isGameOver && !endDialogShown) {
            handleEnd(false);
            return;
        }
    }

    private LinkedList<Position> parseBodyFromBuffer(ByteBuffer buf) {
        LinkedList<Position> list = new LinkedList<>();
        if (buf == null) return list;
        ByteBuffer b = buf.duplicate().order(ByteOrder.nativeOrder());
        int length = b.getInt(32);
        int maxSegments = 300;
        if (length < 0) length = 0;
        if (length > maxSegments) length = maxSegments;
        int offset = 44;
        for (int i = 0; i < length; i++) {
            int idx = offset + i * 2;
            if (idx + 1 >= b.capacity()) break;
            int x = Byte.toUnsignedInt(b.get(idx));
            int y = Byte.toUnsignedInt(b.get(idx + 1));
            list.add(new Position(x, y));
        }
        return list;
    }

    private void handleEnd(boolean win) {
        endDialogShown = true;
        try { if (gameLoop != null) gameLoop.stop(); } catch (Exception ignored) {}

        String title = win ? "¡GANASTE!" : "GAME OVER";
        String message = win ? "Has llenado el mapa. ¿Quieres volver a jugar?" : "Perdiste. ¿Quieres volver a jugar?";

        try {
            SwingUtilities.invokeAndWait(() -> {
                String[] options = {"Volver a jugar", "Salir"};
                int choice = JOptionPane.showOptionDialog(
                        GamePanel.this,
                        message,
                        title,
                        JOptionPane.DEFAULT_OPTION,
                        JOptionPane.QUESTION_MESSAGE,
                        null,
                        options,
                        options[0]
                );

                if (choice == 0) {
                    isGameOver = false;
                    endDialogShown = false;
                    score = 0;
                    if (nativeAPI != null && gameStateBuffer != null) {
                        try {
                            nativeAPI.gameInit(gameStateBuffer, COLS, ROWS);
                            prevStateBuffer.clear();
                            ByteBuffer tmp = gameStateBuffer.duplicate(); tmp.rewind();
                            prevStateBuffer.put(tmp);
                            LinkedList<Position> currBody = parseBodyFromBuffer(gameStateBuffer);
                            snake.getBody().clear(); snake.getBody().addAll(currBody);
                            snake.getPrevBody().clear(); snake.getPrevBody().addAll(currBody);
                            int fx = gameStateBuffer.getInt(24); int fy = gameStateBuffer.getInt(28);
                            try { food.setPosition(new Position(fx, fy)); } catch (Exception ignored) {}
                        } catch (UnsatisfiedLinkError e) {
                            initGame();
                        }
                    } else {
                        initGame();
                    }

                    gameLoop = new GameLoop(GamePanel.this);
                    gameLoop.start();
                } else {
                    System.exit(0);
                }
            });
        } catch (Exception ex) {
            String[] options = {"Volver a jugar", "Salir"};
            int choice = JOptionPane.showOptionDialog(
                    GamePanel.this,
                    message,
                    title,
                    JOptionPane.DEFAULT_OPTION,
                    JOptionPane.QUESTION_MESSAGE,
                    null,
                    options,
                    options[0]
            );
            if (choice == 0) {
                initGame();
                gameLoop = new GameLoop(GamePanel.this);
                gameLoop.start();
            } else {
                System.exit(0);
            }
        }
    }

    public void renderGame(float alpha) {
        this.currentAlpha = alpha;
        SwingUtilities.invokeLater(this::repaint);
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        Graphics2D g2 = (Graphics2D) g;

        drawBackground(g2);

        if (snake != null && food != null) {
            renderer.draw(g2, snake, food, isGameOver ? 1.0f : currentAlpha);
        }
        
        g2.setColor(Color.WHITE);
        g2.setFont(new Font("Arial", Font.BOLD, 18));
        
        g2.drawString("Modo: ASM x86", 10, SCREEN_HEIGHT - 10);
        g2.drawString("Score: " + score, 10, 20);

        if (isGameOver) {
            renderer.drawGameOver(g2, getWidth(), getHeight(), score);
        }
    }
    
    private void drawBackground(Graphics2D g2) {
        Color c1 = new Color(30, 30, 30);
        Color c2 = new Color(25, 25, 25);
        for (int row = 0; row < ROWS; row++) {
            for (int col = 0; col < COLS; col++) {
                g2.setColor((row + col) % 2 == 0 ? c1 : c2);
                g2.fillRect(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE);
            }
        }
    }

    private class ControlHandler extends KeyAdapter {
        @Override
        public void keyPressed(KeyEvent e) {
            if (isGameOver) {
                if (e.getKeyCode() == KeyEvent.VK_ENTER) initGame();
                return;
            }

            int dir = -1;
            switch (e.getKeyCode()) {
                case KeyEvent.VK_W: case KeyEvent.VK_UP:    dir = 0; break;
                case KeyEvent.VK_S: case KeyEvent.VK_DOWN:  dir = 1; break;
                case KeyEvent.VK_A: case KeyEvent.VK_LEFT:  dir = 2; break;
                case KeyEvent.VK_D: case KeyEvent.VK_RIGHT: dir = 3; break;
            }

            if (dir != -1) {
                nativeAPI.gameSetInput(gameStateBuffer, dir);
            }
        }
    }
}