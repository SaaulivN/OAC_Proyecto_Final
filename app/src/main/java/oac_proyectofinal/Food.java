package oac_proyectofinal;
import java.util.Random;

public class Food {
    private Position position;
    private final Random rand = new Random();

    public Food(int width, int height, Snake snake) {
        spawn(width, height, snake);
    }

    public void spawn(int width, int height, Snake snake) {
        boolean valid = false;
        while (!valid) {
            int x = rand.nextInt(width);
            int y = rand.nextInt(height);
            position = new Position(x, y);

            valid = true;
            for (Position p : snake.getBody()) {
                if (p.equalsPos(position)) {
                    valid = false;
                    break;
                }
            }
        }
    }

    public Position getPosition() { return position; }

    public void setPosition(Position p) {
        this.position = p;
    }
}