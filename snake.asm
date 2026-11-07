# Snake - MIPS (MARS 4.5)
# Bitmap Display: unit 8 x 8, display 512 x 512, base address $gp (0x10008000)
# Keyboard and Display MMIO Simulator: connect, type in its lower box
# Controls: w a s d = move, p = pause, r = restart, q = quit

.eqv WALL_COLOR   0x00808080
.eqv SNAKE_COLOR  0x0000FF00
.eqv FOOD_COLOR   0x00FF0000
.eqv BG_COLOR     0x00000000

.eqv KEY_CTRL     0xFFFF0000
.eqv KEY_DATA     0xFFFF0004

.eqv BUF_MASK     4095
.eqv GROW_AMOUNT  3

.eqv START_DELAY  100
.eqv MIN_DELAY    40
.eqv SPEEDUP      5

.data

head_x:   .word 32
head_y:   .word 32
dir_x:    .word 1
dir_y:    .word 0

head_idx: .word 0
tail_idx: .word 0
grow:     .word 5
score:    .word 0
paused:   .word 0

body:     .space 16384

msg_over:  .asciiz "\nGame Over! Score: "
msg_len:   .asciiz "  Length: "
msg_again: .asciiz "\nPress r to restart, q to quit\n"

.text

main:
	jal	init_game

game_loop:
	jal	read_input

	lw	$t0, paused
	bnez	$t0, tick_sleep

	lw	$t0, head_x
	lw	$t1, dir_x
	addu	$t2, $t0, $t1
	sw	$t2, head_x

	lw	$t0, head_y
	lw	$t1, dir_y
	addu	$t2, $t0, $t1
	sw	$t2, head_y

	lw	$a0, head_x
	lw	$a1, head_y
	jal	get_pixel

	beq	$v0, WALL_COLOR, game_over
	beq	$v0, SNAKE_COLOR, game_over

	bne	$v0, FOOD_COLOR, no_food

	lw	$t0, grow
	addiu	$t0, $t0, GROW_AMOUNT
	sw	$t0, grow

	lw	$t0, score
	addiu	$t0, $t0, 1
	sw	$t0, score

	jal	spawn_food

no_food:

	lw	$t0, head_x
	lw	$t1, head_y
	lw	$t2, head_idx
	addiu	$t2, $t2, 1
	andi	$t2, $t2, BUF_MASK
	sw	$t2, head_idx

	sll	$t3, $t1, 6
	addu	$t3, $t0, $t3

	sll	$t2, $t2, 2
	la	$t4, body
	addu	$t4, $t4, $t2
	sw	$t3, 0($t4)

	lw	$a0, head_x
	lw	$a1, head_y
	li	$a2, SNAKE_COLOR
	jal	draw_pixel

	lw	$t0, grow
	beq	$t0, 0, remove_tail
	addiu	$t0, $t0, -1
	sw	$t0, grow
	j	tick_sleep

remove_tail:

	la	$t0, body
	lw	$t1, tail_idx
	sll	$t1, $t1, 2
	addu	$t2, $t1, $t0
	lw	$t3, 0($t2)

	andi	$a0, $t3, 63
	srl	$a1, $t3, 6
	li	$a2, BG_COLOR
	jal	draw_pixel

	lw	$t1, tail_idx
	addiu	$t1, $t1, 1
	andi	$t1, $t1, BUF_MASK
	sw	$t1, tail_idx

tick_sleep:

	lw	$t0, score
	mul	$t1, $t0, SPEEDUP
	li	$t0, START_DELAY
	sub	$t2, $t0, $t1

	slti 	$t3, $t2, MIN_DELAY
	li	$t0, MIN_DELAY
	movn	$t2, $t0, $t3

	move	$a0, $t2
	li	$v0, 32
	syscall

	j	game_loop

game_over:

	la	$a0, msg_over
	li	$v0, 4
	syscall

	lw	$a0, score
	li	$v0, 1
	syscall

	lw	$t0, head_idx
	lw	$t1, tail_idx
	sub	$t2, $t0, $t1
	andi	$t2, $t2, BUF_MASK
	addiu	$t2, $t2, 1

	la	$a0, msg_len
	li	$v0, 4
	syscall

	move	$a0, $t2
	li	$v0, 1
	syscall

	la	$a0, msg_again
	li	$v0, 4
	syscall

wait_key:

	li	$a0, 50
	li	$v0, 32
	syscall

	lw	$t0, KEY_CTRL
	andi	$t0, $t0, 1
	beqz	$t0, wait_key

	lw	$t0, KEY_DATA
	beq	$t0, 'r', restart
	beq	$t0, 'q', quit
	j	wait_key

restart:
	j	main

quit:
	li	$v0, 10
	syscall

init_game:
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)

	la	$t0, 0x10008000
	la	$t1, 0x1000C000
clear_loop:
	sw	$zero, 0($t0)
	addiu	$t0, $t0, 4
	blt	$t0, $t1, clear_loop

	jal	draw_border

	li	$t0, 32
	sw	$t0, head_x
	sw	$t0, head_y
	li	$t0, 1
	sw	$t0, dir_x
	sw	$zero, dir_y
	sw	$zero, head_idx
	sw	$zero, tail_idx
	li	$t0, 5
	sw	$t0, grow
	sw	$zero, score
	sw	$zero, paused

	lw	$t0, head_x
	lw	$t1, head_y
	sll	$t2, $t1, 6
	addu	$t3, $t0, $t2
	la	$t2, body
	sw	$t3, 0($t2)

	move	$a0, $t0
	move	$a1, $t1
	li	$a2, SNAKE_COLOR
	jal	draw_pixel

	li	$a0, 42
	li	$a1, 32
	li	$a2, FOOD_COLOR
	jal	draw_pixel

	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	jr	$ra

spawn_food:
	addiu	$sp, $sp, -12
	sw	$ra, 8($sp)
	sw	$s0, 4($sp)
	sw	$s1, 0($sp)

spawn_retry:

	li	$a0, 2006
	li	$a1, 62
	li	$v0, 42
	syscall
	addiu	$s0, $a0, 1

	li	$a0, 2006
	li	$a1, 62
	li	$v0, 42
	syscall
	addiu	$s1, $a0, 1

	move	$a0, $s0
	move	$a1, $s1
	jal	get_pixel
	bne	$v0, BG_COLOR, spawn_retry

	move	$a0, $s0
	move	$a1, $s1
	li	$a2, FOOD_COLOR
	jal	draw_pixel

	lw	$s1, 0($sp)
	lw	$s0, 4($sp)
	lw	$ra, 8($sp)
	addiu	$sp, $sp, 12
	jr	$ra

read_input:
	lw	$t0, KEY_CTRL
	andi	$t0, $t0, 1
	beq	$t0, 0, input_done

	lw	$t0, KEY_DATA
	beq	$t0, 'p', key_p

	lw	$t1, paused
	bnez	$t1, input_done

	beq	$t0, 'w', key_w
	beq	$t0, 's', key_s
	beq	$t0, 'a', key_a
	beq	$t0, 'd', key_d
	j	input_done

key_w:
	lw	$t0, dir_y
	beq	$t0, 1, input_done
	sw	$zero, dir_x
	li	$t0, -1
	sw	$t0, dir_y
	j	input_done

key_s:
	lw	$t0, dir_y
	beq	$t0, -1, input_done
	sw	$zero, dir_x
	li	$t0, 1
	sw	$t0, dir_y
	j	input_done

key_a:
	lw	$t0, dir_x
	beq	$t0, 1, input_done
	li	$t0, -1
	sw	$t0, dir_x
	sw	$zero, dir_y
	j	input_done

key_d:
	lw	$t0, dir_x
	beq	$t0, -1, input_done
	li	$t0, 1
	sw	$t0, dir_x
	sw	$zero, dir_y
	j	input_done

key_p:
	lw	$t0, paused
	xori	$t0, $t0, 1
	sw	$t0, paused

input_done:
	jr	$ra

draw_border:
	addiu	$sp, $sp, -8
	sw	$ra, 4($sp)
	sw	$s0, 0($sp)

	li	$s0, 0
border_loop:
	move	$a0, $s0
	li	$a1, 0
	li	$a2, WALL_COLOR
	jal	draw_pixel

	move	$a0, $s0
	li	$a1, 63
	li	$a2, WALL_COLOR
	jal	draw_pixel

	li	$a0, 0
	move	$a1, $s0
	li	$a2, WALL_COLOR
	jal	draw_pixel

	li	$a0, 63
	move	$a1, $s0
	li	$a2, WALL_COLOR
	jal	draw_pixel

	addiu	$s0, $s0, 1
	blt	$s0, 64, border_loop

	lw	$s0, 0($sp)
	lw	$ra, 4($sp)
	addiu	$sp, $sp, 8
	jr	$ra

draw_pixel:
	la	$t0, 0x10008000
	sll	$t1, $a1, 6
	addu	$t2, $t1, $a0
	sll	$t3, $t2, 2
	addu	$t4, $t3, $t0
	sw	$a2, 0($t4)
	jr	$ra

get_pixel:
	la	$t0, 0x10008000
	sll	$t1, $a1, 6
	addu	$t2, $t1, $a0
	sll	$t3, $t2, 2
	addu	$t4, $t3, $t0
	lw	$v0, 0($t4)
	jr	$ra
