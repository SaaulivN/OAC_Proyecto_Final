package oac_proyectofinal;

public class Position {
    private int x;
    private int y;

    public Position(int x, int y) {
        this.x = x;
        this.y = y;
    }

    public void setX(int x) { 
        this.x = x; 
    }
    
    public void setY(int y) { 
        this.y = y; 
    }

    public int x() { return x; }
    public int y() { return y; }
    
    public int getX() { return x; }
    public int getY() { return y; }

    public boolean equalsPos(Position other) {
        return this.x == other.x && this.y == other.y;
    }
    
    @Override
    public String toString() {
        return "Position[" + x + ", " + y + "]";
    }
}