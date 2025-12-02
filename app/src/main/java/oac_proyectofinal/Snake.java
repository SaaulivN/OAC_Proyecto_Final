package oac_proyectofinal;
import java.util.LinkedList;
import java.util.Deque;
import java.util.concurrent.ConcurrentLinkedDeque;

public class Snake {
    private LinkedList<Position> body = new LinkedList<>();
    private LinkedList<Position> prevBody = new LinkedList<>();
    
    private Deque<Direction> inputQueue = new ConcurrentLinkedDeque<>();
    
    private Direction currentDirection = Direction.RIGHT;
    private boolean isGrowing = false;

    public Snake(int startX, int startY) {
        Position head = new Position(startX, startY);
        body.add(head);
        prevBody.add(head);
    }

    public void update() {
        prevBody.clear();
        prevBody.addAll(body);

        processNextDirection();

        Position head = body.getFirst();
        Position newHead = switch (currentDirection) {
            case UP -> new Position(head.x(), head.y() - 1);
            case DOWN -> new Position(head.x(), head.y() + 1);
            case LEFT -> new Position(head.x() - 1, head.y());
            case RIGHT -> new Position(head.x() + 1, head.y());
        };

        body.addFirst(newHead);
        if (isGrowing) {
            isGrowing = false;
        } else {
            body.removeLast();
        }
    }

    private void processNextDirection() {
        if (!inputQueue.isEmpty()) {
            Direction nextDir = inputQueue.poll();
            if (!currentDirection.isOpposite(nextDir)) {
                currentDirection = nextDir;
            } else if (!inputQueue.isEmpty()) {
                processNextDirection(); 
            }
        }
    }

    public void addDirectionInput(Direction dir) {
        if (inputQueue.size() < 2) {
            Direction lastInQueue = inputQueue.peekLast();
            if (lastInQueue != dir) {
                inputQueue.add(dir);
            }
        }
    }

    public void grow() {
        this.isGrowing = true;
    }

    public boolean checkSelfCollision() {
        Position head = body.getFirst();
        for (int i = 1; i < body.size(); i++) {
            if (head.equalsPos(body.get(i))) return true;
        }
        return false;
    }

    public boolean checkWallCollision(int width, int height) {
        Position head = body.getFirst();
        return head.x() < 0 || head.x() >= width || head.y() < 0 || head.y() >= height;
    }

    public Position getHead() { return body.getFirst(); }
    public LinkedList<Position> getBody() { return body; }
    public LinkedList<Position> getPrevBody() { return prevBody; }
    public Direction getCurrentDirection() { return currentDirection; }
}