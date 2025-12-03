.386
.model flat, c

DIRECTION_UP    equ 0
DIRECTION_DOWN  equ 1
DIRECTION_LEFT  equ 2
DIRECTION_RIGHT equ 3

.code

game_init PROC

    ; ESI es el punter base para el juego completo

    ; Guardamos el puntero base para establecer uno nuevo
        push ebp
        mov ebp, esp

    ; Guardamos los registros que vamos a usar
        push ebx
        push esi
        push edi
    
        ; Cargamos en ESI la direccion del buffer de memoria
            mov esi, [ebp + 8]
        ; Ponemos en 0 EDI para una bandera de ayuda
            xor edi, edi
        ; Cargamos el ancho del mapa en EAX
            mov eax, [ebp + 12]
        ; Cargamos el alto del mapa en EBX    
            mov ebx, [ebp + 16]
    
        ; Guardamos el ancho en la memoria
            mov [esi + 0], eax
        ; Guardamos el alto en la memoria
            mov [esi + 4], ebx
        ; -----------------------------------------------------------------------
        mov dword ptr [esi + 8], 20 ; Puntuacion
        ; -----------------------------------------------------------------------
        ; La funcion isGameOver en falso para que inicie el juego
            mov dword ptr [esi + 12], 0
    
    ; En esta parte calculamos el centro

        ; Dividimos entre 2 la mitad del ancho
            shr eax, 1
        ; Dividimos entre 2 la mitad del alto
            shr ebx, 1
        ; Guardamos las coordenadas de la cabeza en el centro (x,y)
            mov [esi + 16], eax
            mov [esi + 20], ebx
    
    mov dword ptr [esi + 24], 2
    mov dword ptr [esi + 28], 2
    ; -----------------------------------------------------------------------
    mov dword ptr [esi + 32], 3 ; Longitud_Inicial
    ; -----------------------------------------------------------------------

    ; Establecemos una direccion iniciar (derecha)
        mov dword ptr [esi + 36], DIRECTION_RIGHT
        mov dword ptr [esi + 40], DIRECTION_RIGHT

    ; Aqui cargamos las coordenadas de la cabeza
        mov eax, [esi + 16]     ; Coordenada X
        mov ebx, [esi + 20]     ; Coordenada Y

    ; El vector del cuerpo enpieza en el offset 44 
    ; Cada parte necesita 2 bytes, uno para cada coordenada (x,y)
        mov byte ptr [esi + 44], al
        mov byte ptr [esi + 45], bl

    ; Cargamos el cuerpo inicial de la serpiente a la izquierda de la cabeza 
    ; Movemos la X a AL
        mov al, [esi + 16]
    ; Le restamos 1 a X
        sub al, 1
    ; Guardamos la coordenada nueva de X en el siguiente espacio
        mov byte ptr [esi + 46], al
    ; Guardamos Y, esta sigue intacta
        mov byte ptr [esi + 47], bl

    ; En esta parte creamos el cuerpo de la serpiente
    ; Le damos la X original
        mov al, [esi + 16]
    ; Le restamos 2 a la X (cabeza)
        sub al, 2
    ; Aqui guardamos X en el tercer espacio
        mov byte ptr [esi + 48], al
    ; Guardamos la Y que sigue siendo la misma
        mov byte ptr [esi + 49], bl
    
    ; Restauramos los registros y los retornamos
        pop edi
        pop esi
        pop ebx
        pop ebp
        ret
game_init ENDP

; La funcion se ejecuta 60 veces por segundo definido por java
game_tick PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    
    mov esi, [ebp + 8]
    
    ; Comprueba si isGameOver es falso
        cmp dword ptr [esi + 12], 0
    ; Con la bandera si es uno, salta al final y no hace nada
        jne tick_done
    
    ; Lee la siguiente direccion que presiono el usuario
        mov eax, [esi + 40]
    ; Aqui la convertimos a direccion actual
        mov [esi + 36], eax
    
    mov eax, [esi + 16]
    mov ebx, [esi + 20]
    
    mov ecx, [esi + 36]
    
    ; Esta parte es importante porque es la que decide la serpiente a que direccion ir
    ; Dependiendo la tecla que presione el usuario, la serpiente decide a que parte del codigo saltar (linea 122-134)
        cmp ecx, DIRECTION_UP
        je tick_move_up
        cmp ecx, DIRECTION_DOWN
        je tick_move_down
        cmp ecx, DIRECTION_LEFT
        je tick_move_left
        cmp ecx, DIRECTION_RIGHT
        je tick_move_right
        jmp tick_check_bounds
    
    tick_move_up:
        ; Si se mueve para arriba, decrementa Y
        dec dword ptr [esi + 20]
        jmp tick_check_bounds
        
    tick_move_down:
        ; Si se mueve para abajo, incrementa Y
        inc dword ptr [esi + 20]
        jmp tick_check_bounds
        
    tick_move_left:
        ; Si se mueve para la izquierda, decrementa X
        dec dword ptr [esi + 16]
        jmp tick_check_bounds
        
    tick_move_right:
        ; Si se mueve para la derecho, incrementa X
        inc dword ptr [esi + 16]
        
    tick_check_bounds:
        mov eax, [esi + 16]
        mov ebx, [esi + 20]
    
    ; Si X < 0 significa que chocaste
        cmp eax, 0
        jl tick_game_over 
        mov ecx, [esi + 0]
    ; Si X => ancho, chocaste
        cmp eax, ecx
        jge tick_game_over
    
    cmp ebx, 0
    jl tick_game_over
    mov ecx, [esi + 4]
    cmp ebx, ecx
    jge tick_game_over
    
    ; En esta parte comparamos las coordenadas de la cabeza de la serpiente con la coordenada de la manzana
    xor edi, edi
    mov eax, [esi + 16]
    mov ebx, [esi + 20]

    ; Primero comparamos la coordenada en X
        cmp eax, [esi + 24]
        ; Salta a la funcion que nos dice que no hay coincidencia de coordenadas, por lo que no incrementa la serpiente
        jne tick_no_food
    ; Despues comparamos la coordenada en Y
        cmp ebx, [esi + 28]
        ; Salta a la funcion que nos dice que no hay coincidencia de coordenadas, por lo que no incrementa la serpiente        
        jne tick_no_food
    
    ; Sumamos 1 al puntaje si ambas coordenadas coinciden
        inc dword ptr [esi + 8]
    ; Marcamos 1 a la bandera para decir que la serpiente crecio en 1
        mov edi, 1

    mov eax, [esi + 24]
    add eax, 3
    mov ecx, [esi + 0]
    xor edx, edx
    cmp eax, ecx
    jl food_x_ok
    mov eax, 2

    food_x_ok:
        ; Guarda la nueva manzana en offset 24
            mov [esi + 24], eax
        
        ; Cargamos la manzana en Y de antes
            mov eax, [esi + 28]
        ; Le sumamos 3 para que se mueva
            add eax, 3
        ; Cargamos la altura del mapa
            mov ecx, [esi + 4]
        ; Comparamos la coordenada nueva de Y con la altura
            cmp eax, ecx
        ; Si esta dentro del mapa salta para guardar
            jl food_y_ok
        ; Si se sale del mapa, la posicion la regresa a 2
            mov eax, 2
    food_y_ok:
        ; Guardamos la manzan en Y
            mov [esi + 28], eax 
        
    tick_no_food:
        ; Cargamos la longitud actual
            mov eax, [esi + 32]
        ; Comparamos con el limite maximo (300 en este caso)
            cmp eax, 300
        ; Si ya es muy grande, adios (aparte no desborda la memoria)
        jge tick_body_ok

        ; Preguntamos si la longitud es 0
            cmp eax, 0
        ; Si no hay cuerpo entonces no hay niguna serpiente para mover
            je after_shift

        ; Empezamos un contador para el ciclo
            mov ecx, eax
        ; Decrementamos la longitud en 1 para empezar desde la ultima parte del cuerpo
            dec ecx
        ; Verificacion extra, si es menor a 0, adios.
            cmp ecx, 0
            jl shift_done

    shift_loop:
        ; Calculamos la parte actual de la direccion en memoria
        ; EDX es nuestro indice actual
            mov edx, ecx
        ; Como cada parte del cuerpo son 2 bytes, multiplicamos por 2
            shl edx, 1
        ; Sumamos 44 porque es el vector del cuerpo
            add edx, 44
        
        ; Cargamos la coordenada en X de la parte del cuerpo actual
            mov al, byte ptr [esi + edx]
        ; La guardamos en la X de la siguiente parte del cuerpo
            mov byte ptr [esi + edx + 2], al

        ; Lo mismo para la coordenada Y, cargamos la Y de la parte actual
            mov al, byte ptr [esi + edx + 1]
        ; La guardamos en la Y de la siguiente parte del cuerpo
            mov byte ptr [esi + edx + 3], al

        ; Comparamos si llegamos al indice de 0
            cmp ecx, 0
        ; Si llegamos a 0, terminamos de mover el cuerpo
            je shift_done
        ; Decrementamos el contador y repetimos el bucle si no llegamos a 0
            dec ecx
            jmp shift_loop

    ; En esta parte conectamos la cabeza al cuerpo
    shift_done:
        ; Copiamos la posicion actual de la cabeza a la primer parte del cuerpo
        ; Cargamos la direccion X de la cabeza
            mov al, byte ptr [esi + 16]
        ; Guardamos la direccion X de la cabeza
            mov byte ptr [esi + 44], al

        ; Cargamos la direccion Y de la cabeza
            mov al, byte ptr [esi + 20]
        ; Guardamos la direccion Y de la cabeza
            mov byte ptr [esi + 45], al

    ; Aqui nos encargamos del crecimiento de la serpiente
    after_shift:
        ; Revisamos la bandera EDI (EDI = 1 si comia)
            cmp edi, 1
        ; Si no es 1, significa que no comio, por lo que no crecera
            jne tick_body_ok
        ; Si es 1, incrementa en 1 la longitud, por lo que al ser mas larga, el proximo bucle shift_loop durarar un ciclo mas
            inc dword ptr [esi + 32]

        ; Salta al final 
        jmp tick_body_ok
        
    tick_body_ok:
        ; Si todo salio bien, terminamos
            jmp tick_done
        
    tick_game_over:
        ; Condicion para que termine el juego, ponemos isGameOver en 1
            mov dword ptr [esi + 12], 1
        
    tick_done:
        ; Restauramos los registros guardados
            pop edi
            pop esi
            pop ebx
            pop ebp
        ; Regresa a java
            ret
game_tick ENDP

; Esta funcion lee la tecla que presiono el usuario
game_set_input PROC
    push ebp
    mov ebp, esp
    
    mov eax, [ebp + 8]
    mov ecx, [ebp + 12]
    
    mov edx, [eax + 36]
    
    ; No puedes ir hacia abajo si vas hacia arriba, es decir, no puedes dar media vuelta sino chocarias con tu cuerpo
    ; Direccion actual
        mov eax, edx
    ; Direccion nueva
        xor eax, ecx
    ; Lo que pasa aqui es que si compara y es 1, significa que hiciste un giro invalido por lo que salta a una funcion para que invalide la tecla que presiono el usuario
        cmp eax, 1
        je input_invalid
    
    mov eax, [ebp + 8]
    mov [eax + 40], ecx
    
    ; Funcion para que invalide la tecla del usuario
    input_invalid:
        pop ebp
        ret
game_set_input ENDP

; Funciones simples para que retornen valores importantes como el puntaje y si el juego termino
    game_get_score PROC
        push ebp
        mov ebp, esp
        
        mov eax, [ebp + 8]
        mov eax, [eax + 8]
        
        pop ebp
        ret
    game_get_score ENDP

    game_is_game_over PROC
        push ebp
        mov ebp, esp
        
        mov eax, [ebp + 8]
        mov eax, [eax + 12]
        
        pop ebp
        ret
    game_is_game_over ENDP

END