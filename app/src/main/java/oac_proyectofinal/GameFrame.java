package oac_proyectofinal;
import javax.swing.JFrame;
import javax.swing.SwingUtilities;

public class GameFrame extends JFrame {

    public GameFrame() {
        this.add(new GamePanel());
        this.setTitle("Snake Game");
        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        this.setResizable(false);
        this.pack();
        this.setLocationRelativeTo(null);
        this.setVisible(true);
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(GameFrame::new);
    }
}