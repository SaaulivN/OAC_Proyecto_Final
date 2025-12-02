package oac_proyectofinal;
import java.awt.*;
import java.util.LinkedList;

public class Renderer {
    private final int tileSize;

    public Renderer(int tileSize) {
        this.tileSize = tileSize;
    }

    public void draw(Graphics2D g2, Snake snake, Food food, float alpha) {
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

        drawTile(g2, food.getPosition().x(), food.getPosition().y(), Color.RED);

        LinkedList<Position> currentBody = snake.getBody();
        LinkedList<Position> prevBody = snake.getPrevBody();

        if (prevBody.size() != currentBody.size()) {
            for (Position p : currentBody) {
                drawTile(g2, p.x(), p.y(), Color.BLUE);
            }
        } else {
            g2.setColor(Color.BLUE);
            for (int i = 0; i < currentBody.size(); i++) {
                Position curr = currentBody.get(i);
                Position prev = prevBody.get(i);

                double interpX = prev.x() + (curr.x() - prev.x()) * alpha;
                double interpY = prev.y() + (curr.y() - prev.y()) * alpha;

                g2.fillRect(
                    (int) (interpX * tileSize), 
                    (int) (interpY * tileSize), 
                    tileSize, tileSize
                );
            }
        }

        if (!currentBody.isEmpty()) {
            double headX;
            double headY;
            if (prevBody.size() == currentBody.size() && !prevBody.isEmpty()) {
                Position currHead = currentBody.getFirst();
                Position prevHead = prevBody.getFirst();
                headX = prevHead.x() + (currHead.x() - prevHead.x()) * alpha;
                headY = prevHead.y() + (currHead.y() - prevHead.y()) * alpha;
            } else {
                Position h = currentBody.getFirst();
                headX = h.x();
                headY = h.y();
            }

            Direction dir = snake.getCurrentDirection();

            double pixelX = headX * tileSize;
            double pixelY = headY * tileSize;

            int eyeSize = Math.max(2, tileSize / 5);
            int pupilSize = Math.max(1, eyeSize / 2);

            double centerX = pixelX + tileSize / 2.0;
            double centerY = pixelY + tileSize / 2.0;
            double offset = tileSize / 4.0;

            double ex1 = centerX - offset / 2.0 - eyeSize/2.0;
            double ey1 = centerY - offset / 2.0 - eyeSize/2.0;
            double ex2 = centerX + offset / 2.0 - eyeSize/2.0;
            double ey2 = centerY - offset / 2.0 - eyeSize/2.0;

            switch (dir) {
                case UP:
                    ex1 = centerX - offset / 2.0 - eyeSize/2.0; ey1 = centerY - offset - eyeSize/2.0;
                    ex2 = centerX + offset / 2.0 - eyeSize/2.0; ey2 = centerY - offset - eyeSize/2.0;
                    break;
                case DOWN:
                    ex1 = centerX - offset / 2.0 - eyeSize/2.0; ey1 = centerY + offset - eyeSize/2.0;
                    ex2 = centerX + offset / 2.0 - eyeSize/2.0; ey2 = centerY + offset - eyeSize/2.0;
                    break;
                case LEFT:
                    ex1 = centerX - offset - eyeSize/2.0; ey1 = centerY - offset / 2.0 - eyeSize/2.0;
                    ex2 = centerX - offset - eyeSize/2.0; ey2 = centerY + offset / 2.0 - eyeSize/2.0;
                    break;
                case RIGHT:
                    ex1 = centerX + offset - eyeSize/2.0; ey1 = centerY - offset / 2.0 - eyeSize/2.0;
                    ex2 = centerX + offset - eyeSize/2.0; ey2 = centerY + offset / 2.0 - eyeSize/2.0;
                    break;
            }

            g2.setColor(Color.WHITE);
            g2.fillOval((int) Math.round(ex1), (int) Math.round(ey1), eyeSize, eyeSize);
            g2.fillOval((int) Math.round(ex2), (int) Math.round(ey2), eyeSize, eyeSize);

            g2.setColor(Color.BLACK);
            g2.fillOval((int) Math.round(ex1 + eyeSize / 4.0), (int) Math.round(ey1 + eyeSize / 4.0), pupilSize, pupilSize);
            g2.fillOval((int) Math.round(ex2 + eyeSize / 4.0), (int) Math.round(ey2 + eyeSize / 4.0), pupilSize, pupilSize);
        }
    }

    private void drawTile(Graphics2D g2, double x, double y, Color c) {
        g2.setColor(c);
        g2.fillRect((int)(x * tileSize), (int)(y * tileSize), tileSize, tileSize);
    }
    
    public void drawGameOver(Graphics2D g2, int width, int height, int score) {
        g2.setColor(new Color(0, 0, 0, 150));
        g2.fillRect(0, 0, width, height);
        
        g2.setColor(Color.WHITE);
        g2.setFont(new Font("Arial", Font.BOLD, 40));
        String text = "GAME OVER";
        int tx = (width - g2.getFontMetrics().stringWidth(text)) / 2;
        g2.drawString(text, tx, height / 2 - 20);
        
        g2.setFont(new Font("Arial", Font.PLAIN, 20));
        String scoreText = "Final Score: " + score;
        int sx = (width - g2.getFontMetrics().stringWidth(scoreText)) / 2;
        g2.drawString(scoreText, sx, height / 2 + 20);
        
        String resetText = "Press ENTER to Restart";
        int rx = (width - g2.getFontMetrics().stringWidth(resetText)) / 2;
        g2.drawString(resetText, rx, height / 2 + 60);
    }
}