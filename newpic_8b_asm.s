PROCESSOR 18F4550

// CONFIG1L
config PLLDIV = 1       // PLL Prescaler Selection bits (No prescale (4 MHz oscillator input drives PLL directly))
config CPUDIV = OSC1_PLL2// System Clock Postscaler Selection bits ([Primary Oscillator Src: /1][96 MHz PLL Src: /2])
config USBDIV = 1       // USB Clock Selection bit (used in Full-Speed USB mode only; UCFG:FSEN = 1) (USB clock source comes directly from the primary oscillator block with no postscale)

// CONFIG1H
config FOSC = INTOSC_HS        // Oscillator Selection bits (HS oscillator (HS))
config FCMEN = OFF      // Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
config IESO = OFF       // Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)

// CONFIG2L
config PWRT = OFF       // Power-up Timer Enable bit (PWRT disabled)
config BOR = ON         // Brown-out Reset Enable bits (Brown-out Reset enabled in hardware only (SBOREN is disabled))
config BORV = 3         // Brown-out Reset Voltage bits (Minimum setting 2.05V)
config VREGEN = OFF     // USB Voltage Regulator Enable bit (USB voltage regulator disabled)

// CONFIG2H
config WDT = OFF        // Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
config WDTPS = 32768    // Watchdog Timer Postscale Select bits (1:32768)

// CONFIG3H
config CCP2MX = ON      // CCP2 MUX bit (CCP2 input/output is multiplexed with RC1)
config PBADEN = OFF     // PORTB A/D Enable bit (PORTB<4:0> pins are configured as digital I/O on Reset)
config LPT1OSC = OFF    // Low-Power Timer 1 Oscillator Enable bit (Timer1 configured for higher power operation)
config MCLRE = ON       // MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)

// CONFIG4L
config STVREN = ON      // Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset)
config LVP = OFF        // Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
config ICPRT = OFF      // Dedicated In-Circuit Debug/Programming Port (ICPORT) Enable bit (ICPORT disabled)
config XINST = OFF       // Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode enabled)

// CONFIG5L
config CP0 = OFF        // Code Protection bit (Block 0 (000800-001FFFh) is not code-protected)
config CP1 = OFF        // Code Protection bit (Block 1 (002000-003FFFh) is not code-protected)
config CP2 = OFF        // Code Protection bit (Block 2 (004000-005FFFh) is not code-protected)
config CP3 = OFF        // Code Protection bit (Block 3 (006000-007FFFh) is not code-protected)

    // CONFIG5H
config CPB = OFF        // Boot Block Code Protection bit (Boot block (000000-0007FFh) is not code-protected)
config CPD = OFF        // Data EEPROM Code Protection bit (Data EEPROM is not code-protected)
// CONFIG6L
config WRT0 = OFF       // Write Protection bit (Block 0 (000800-001FFFh) is not write-protected)
config WRT1 = OFF       // Write Protection bit (Block 1 (002000-003FFFh) is not write-protected)
config WRT2 = OFF       // Write Protection bit (Block 2 (004000-005FFFh) is not write-protected)
config WRT3 = OFF       // Write Protection bit (Block 3 (006000-007FFFh) is not write-protected)

// CONFIG6H
config WRTC = OFF       // Configuration Register Write Protection bit (Configuration registers (300000-3000FFh) are not write-protected)
config WRTB = OFF       // Boot Block Write Protection bit (Boot block (000000-0007FFh) is not write-protected)
config WRTD = OFF       // Data EEPROM Write Protection bit (Data EEPROM is not write-protected)

// CONFIG7L
config EBTR0 = OFF      // Table Read Protection bit (Block 0 (000800-001FFFh) is not protected from table reads executed in other blocks)
config EBTR1 = OFF      // Table Read Protection bit (Block 1 (002000-003FFFh) is not protected from table reads executed in other blocks)
config EBTR2 = OFF      // Table Read Protection bit (Block 2 (004000-005FFFh) is not protected from table reads executed in other blocks)
config EBTR3 = OFF      // Table Read Protection bit (Block 3 (006000-007FFFh) is not protected from table reads executed in other blocks)

// CONFIG7H
config EBTRB = OFF      // Boot Block Table Read Protection bit (Boot block (000000-0007FFh) is not protected from table reads executed in other blocks)

#include <xc.inc>    
GLOBAL duty              ;make this global so it is watchable when debugging
#define motor_pin PORTC_RC0_POSITION
 
;objects in common (Access bank) memory 
PSECT udata_acs
duty:
    DS         1        ;reserve 1 byte for duty

;this must be linked to the reset vector
PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto       main
    
psect   hi_int_vec,class=CODE,reloc=2
    
    goto    HighIsrHandler

psect   lo_int_vec,class=CODE,reloc=2
    
    goto    LowIsrHandler
    
/* find the highest PORTA value read, storing this into
   the object max */
PSECT code,reloc=2 
main:
    ;set up the oscillator
    movlw      0b01100000
    movwf      OSCCON,c
    bsf INTCON,INTCON_GIEH_POSITION,c
    bsf INTCON,INTCON_GIEL_POSITION,c
    movlw 0b01111001
    movwf T2CON,c
    movlw 0x8E
    movwf ADCON1,c
    movlw 0x80
    movwf ADCON0,c
    movlw 0x06
    movwf ADCON2,c
    bsf ADCON0,ADCON0_ADON_POSITION,c
    clrf TRISC,c
    clrf PORTC,c
    bsf TRISA,0,c
    clrf PORTA,c    
    movlw 10
    movwf duty,c
    movwf PR2,c
    bsf T2CON,T2CON_TMR2ON_POSITION,c
    bsf PIE1,PIE1_TMR2IE_POSITION,c
loop:
    bsf ADCON0,ADCON0_GO_DONE_POSITION,c
    btfsc ADCON0,ADCON0_GO_DONE_POSITION,c
    bra $-2
    movff ADRESH,duty,c
    movlw 255
    cpfsgt duty,c
    bra TestLow
IsHigh:
    movwf duty,c
    bra loop
TestLow:
    movlw 10
    cpfslt duty,c
    bra loop
IsLow: 
    movwf duty,c
    bra loop
    
LowIsrHandler:
    btfsc PIR1,PIR1_TMR2IF_POSITION,c
    bra Tmr2Irq
HighIsrHandler:      
    retfie
Tmr2Irq:
    bcf PIR1,PIR1_TMR2IF_POSITION,c
    btfsc PORTC,motor_pin,c
    bra MtrLow
    movff duty,PR2,c
    bra Exit
MtrLow:
    movf duty,w,c
    sublw 0xFF
    movwf PR2,c
Exit:    
    btg PORTC,motor_pin,c
    retfie
    END  resetVec