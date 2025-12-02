/* ============================================================================
 * game_wrapper.c - Wrapper JNI para funciones MASM x86
 * Convierte llamadas JNI a llamadas C (__cdecl) hacia MASM
 * ============================================================================
 */

#include <jni.h>
#include <string.h>

/* Declarar funciones implementadas en MASM (game.asm)
 * Convención: __cdecl x86 32-bit
 */
void __cdecl game_init(void* stateBuffer, int width, int height);
void __cdecl game_tick(void* stateBuffer);
void __cdecl game_set_input(void* stateBuffer, int direction);
int __cdecl game_get_score(void* stateBuffer);
int __cdecl game_is_game_over(void* stateBuffer);

/* ============================================================================
 * Función auxiliar para obtener dirección del buffer directo
 * ============================================================================
 */
static void* getBufferAddress(JNIEnv *env, jobject buffer) {
    void *directBuffer = (*env)->GetDirectBufferAddress(env, buffer);
    if (directBuffer == NULL) {
        (*env)->ThrowNew(env, (*env)->FindClass(env, "java/lang/RuntimeException"),
                         "Buffer no es direct o está readonly");
        return NULL;
    }
    return directBuffer;
}

/* ============================================================================
 * Java_oac_1proyectofinal_GameNative_gameInit
 * ============================================================================
 */
JNIEXPORT void JNICALL Java_oac_1proyectofinal_GameNative_gameInit
  (JNIEnv *env, jobject obj, jobject stateBuffer, jint width, jint height)
{
    void *state = getBufferAddress(env, stateBuffer);
    if (state != NULL) {
        game_init(state, (int)width, (int)height);
    }
}

/* ============================================================================
 * Java_oac_1proyectofinal_GameNative_gameTick
 * ============================================================================
 */
JNIEXPORT void JNICALL Java_oac_1proyectofinal_GameNative_gameTick
  (JNIEnv *env, jobject obj, jobject stateBuffer)
{
    void *state = getBufferAddress(env, stateBuffer);
    if (state != NULL) {
        game_tick(state);
    }
}

/* ============================================================================
 * Java_oac_1proyectofinal_GameNative_gameSetInput
 * ============================================================================
 */
JNIEXPORT void JNICALL Java_oac_1proyectofinal_GameNative_gameSetInput
  (JNIEnv *env, jobject obj, jobject stateBuffer, jint direction)
{
    void *state = getBufferAddress(env, stateBuffer);
    if (state != NULL) {
        game_set_input(state, (int)direction);
    }
}

/* ============================================================================
 * Java_oac_1proyectofinal_GameNative_gameGetScore
 * ============================================================================
 */
JNIEXPORT jint JNICALL Java_oac_1proyectofinal_GameNative_gameGetScore
  (JNIEnv *env, jobject obj, jobject stateBuffer)
{
    void *state = getBufferAddress(env, stateBuffer);
    if (state != NULL) {
        return (jint)game_get_score(state);
    }
    return 0;
}

/* ============================================================================
 * Java_oac_1proyectofinal_GameNative_gameIsGameOver
 * ============================================================================
 */
JNIEXPORT jint JNICALL Java_oac_1proyectofinal_GameNative_gameIsGameOver
  (JNIEnv *env, jobject obj, jobject stateBuffer)
{
    void *state = getBufferAddress(env, stateBuffer);
    if (state != NULL) {
        return (jint)game_is_game_over(state);
    }
    return 0;
}
