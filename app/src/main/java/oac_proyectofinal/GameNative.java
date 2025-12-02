package oac_proyectofinal;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

public class GameNative {
    
    static {
        System.loadLibrary("game"); 
    }

    public native void gameInit(ByteBuffer stateBuffer, int width, int height);
    public native void gameTick(ByteBuffer stateBuffer);
    public native void gameSetInput(ByteBuffer stateBuffer, int direction);
    public native int gameGetScore(ByteBuffer stateBuffer);
    public native int gameIsGameOver(ByteBuffer stateBuffer);
}