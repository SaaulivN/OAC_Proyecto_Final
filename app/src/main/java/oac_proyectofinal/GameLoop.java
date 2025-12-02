package oac_proyectofinal;
import javax.swing.SwingUtilities;

public class GameLoop implements Runnable {

    private final GamePanel gamePanel;
    private boolean running = false;
    private Thread thread;

    private static final double UPS = 8.0;
    private static final double UPDATE_INTERVAL = 1.0 / UPS; 

    public GameLoop(GamePanel panel) {
        this.gamePanel = panel;
    }

    public void start() {
        if (running) return;
        running = true;
        thread = new Thread(this);
        thread.start();
    }

    public void stop() {
        running = false;
        if (thread != null && Thread.currentThread() != thread) {
            try { thread.join(); } catch (InterruptedException e) { e.printStackTrace(); }
        }
    }

    @Override
    public void run() {
        long lastTime = System.nanoTime();
        double accumulator = 0.0;

        while (running) {
            long now = System.nanoTime();
            double frameTime = (now - lastTime) / 1_000_000_000.0; 
            lastTime = now;

            if (frameTime > 0.25) frameTime = 0.25;

            accumulator += frameTime;

            while (accumulator >= UPDATE_INTERVAL) {
                gamePanel.updateGameLogic();
                accumulator -= UPDATE_INTERVAL;
            }

            float alpha = (float) (accumulator / UPDATE_INTERVAL);
            gamePanel.renderGame(alpha);
            
            try { Thread.sleep(1); } catch (InterruptedException ignored) {}
        }
    }
}