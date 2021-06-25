; -------------------------------------------------------------------------------------------------------------------
; Mikrokontroller alapú rendszerek házi feladat
; Készítette: Csizy Ádám
; Neptun code: ******
; Feladat leírása:
;		Belső memóriában tárolt 16 bites kódszavak (tömb)
;		közötti legkisebb Hamming távolság megkeresése.
;		Bemenet: tömb kezdőcíme (mutató), elemek száma.
;		Kimenet: legkisebb távolság számértéke (regiszterben).
;
; 		A feladat végeredménye a 'MOV result, R6' utasításra
; 		(főprogram, 76. sor) elhelyezett törésponton való
;		megállás után áll elő.
; -------------------------------------------------------------------------------------------------------------------



;--------------------------------------------------------------------------------------------------------------------
; Include direktívák, regiszter definíciók:
;--------------------------------------------------------------------------------------------------------------------
$NOMOD51 ; a sztenderd 8051 regiszter definíciók nem szükségesek (névütközés elkerülése)
$INCLUDE (SI_EFM8BB3_Defs.inc) ; regiszter és SFR definíciók (hivatalos, MCU gyártója által rendelkezésünkre bocsátott)



;--------------------------------------------------------------------------------------------------------------------
; Változóknak helyfoglalás az adat memóriában:
;--------------------------------------------------------------------------------------------------------------------
myvariables SEGMENT DATA AT 30h ; saját adatszegmens létrehozása a változóinknak (a változóinknak a 0x30 címtől kezdve (nem bitcímezhető tartomány kezdete) folyamatosan (egybefüggően) foglalja a fordító a helyet)
RSEG myvariables ; saját adatszegmens kiválasztása
result: DS 1 ; 1 bájt adatmemória foglalása a szubrutin visszatérési értékének elmentéséhez



;---------------------------------------------------------------------------------------------------------------------
; Szimbólum definíciók:
;---------------------------------------------------------------------------------------------------------------------
RS0	BIT	0xD3 ; PSW regiszter bank kiválasztó alsó bitje
RS1	BIT 0xD4 ; PSW regiszter bank kiválasztó felső bitje



;---------------------------------------------------------------------------------------------------------------------
; Ugrótábla létrehozása:
;---------------------------------------------------------------------------------------------------------------------
	CSEG ; kód(program)szegmens kiválasztása
	JMP Main

myprog SEGMENT CODE			; saját kódszegmens létrehozása
RSEG myprog 				; saját kódszegmens kiválasztása



; --------------------------------------------------------------------------------------------------------------------
; Főprogram:
; --------------------------------------------------------------------------------------------------------------------
; Feladata: 	A szükséges inicializációs lépések elvégzése és a
;		feladatot megvalósító szubrutin(ok) meghívása.
; --------------------------------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------------------------------
; Konstansok (kódszavak) elhelyezése a program memóriában:
; A specifikáció nem nyilatkozik a kódszavak (tömb)
; módosíthatóságának mivoltáról, se a belső memórián belüli
; elhelyezéséről, ezért memóriatakarékossági megfontolásból
; a kódszavakat (tömb) a programmemóriában (CODE SEGMENT)
; konstansokként helyezzük el.
;---------------------------------------------------------------------------------------------------------------------
;ARRAY:	DB 0CDh, 14h, 0A3h, 75h, 04h, 10h, 4Ch, 0E5h,  0BAh,8Bh, 21h, 0FAh ; 6 elemű tömb inicializálása teszteléshez
; ARRAY: [0]: 14CDh, [1]: 75A3h, [2]: 1004h, [3]: 0E54Ch, [4]: 8BBAh, [5]: 0FA21h (LITTLE ENDIAN)

ARRAY: DB 00h, 00h, 0FFh, 0FFh ; 2 elemű tömb inicializálása teszteléshez
; ARRAY: [0]: 0000h, [1]: 0FFFFh (LITTLE ENDIAN) (Hamming távolság: 16 (10h))

Main:
	CLR IE_EA ; interruptok tiltása watchdog tiltás idejére
	MOV WDTCN,#0DEh ; watchdog timer tiltása
	MOV WDTCN,#0ADh
	SETB IE_EA ; interruptok engedélyezése

	; paraméterek előkészítése a szubrutin híváshoz
	MOV DPTR, #ARRAY ; tömb kezdőcím betöltése DPTR-be, ezt kapja a szubrutin bemenetként
	MOV R7, #02h ; tömb elemszám betöltése R7-be, ezt kapja a szubrutin bemenetként
	LCALL Min_Hamming_Distance ; szubrutin hívása
	MOV result, R6 ; szubrutin visszatérési értékének elmentése
	JMP $ ; végtelen ciklusban várunk



; ---------------------------------------------------------------------------------------------------------------------
; Min_Hamming_Distance szubrutin
; ---------------------------------------------------------------------------------------------------------------------
; Funkció: 			Belső memóriában tárolt 16 bites kódszavak
;				(tömb) közötti legkisebb Hamming távolság
;				megkeresése.
; 			
; Bemenetek:			DPTR - tömb kezdőcíme
;			 	R7 - tömb elemszáma
;
; Kimenetek:  			R6 - minimális Hamming távolság
;				
; Regisztereket módosítja:	A
;				R6, R5, R4, R3, R2, R1, R0 (regiszter bank 0)
;				R7, R6, R5, R4 (regiszter bank 1)
; 
; Flageket módosítja:		CY, OV, AC
; ----------------------------------------------------------------------------------------------------------------------
Min_Hamming_Distance:

			USING 0 ; használt regiszterbank (RB 0) kiválasztása PUSH művelethez (regiszterek miatt)

			PUSH PSW ; PSW stackre mentése
			PUSH ACC ; akkumulátor stackre mentése

			PUSH AR5 ; R5 regiszter stackre mentése
			PUSH AR4 ; R4 regiszter stackre mentése
			PUSH AR3 ; R3 regiszter stackre mentése
			PUSH AR2 ; R2 regiszter stackre mentése
			PUSH AR1 ; R1 regiszter stackre mentése
			PUSH AR0 ; R0 regiszter stackre mentése

			USING 1 ; használt regiszterbank (RB 1) kiválasztása PUSH művelethez (regiszterek miatt)

			PUSH AR7 ; R7 regiszter stackre mentése
			PUSH AR6 ; R6 regiszter stackre mentése
			PUSH AR5 ; R5 regiszter stackre mentése
			PUSH AR4 ; R4 regiszter stackre mentése

			MOV R6, #10h ; minimális Hamming távolságot tároló regiszter inicializálása a legnagyobb távolságra (16 bit esetén ez 16)

			SETB RS0 ; 1-es regiszter bankra váltás
			CLR RS1

			MOV R5, #00h ; (RB1) topiteráció indexének 0-ra inicializálása

			CLR RS0 ; 0-s regiszter bankra váltás
			CLR RS1

			MOV A, R7 ; tömb méretének eltárolása az R0 regiszterben, iteráció során fokozatosan csökkentjük, R7-et (eredeti érték) változatlanul hagyjuk, mert szükségünk lesz még rá
			MOV R0, A
			DEC R0 ; tömb méretének csökkentése 1-el, hogy ne vizsgáljuk az utolsó elemet önmagával (ekkor 0 lesz a minimális Hamming távolság)

Top_Iter:		SETB RS0 ; 1-es regiszter bankra váltás
			CLR RS1


			MOV A, R5 ; (RB1) topiteráió aktuális indexének akkumulátorba töltése a bázisregiszter + indexregiszteres címzéshez
			MOVC A, @A+DPTR ; aktuálisan vizsgált kódszó alsó bájtjának beolvasása a kódmemóriából
			MOV R6, A ; (RB1) aktuálisan vizsgált kódszó alsó bájtjának eltárolása az R6 regiszterben

			INC R5 ; (RB1) a topiteráció indexének növelése

			MOV A, R5 ; (RB1) topiteráció aktuális indexének akkumulátorba töltése a bázisregiszter + indexregiszteres címzéshez
			MOVC A, @A+DPTR ; aktuálisan vizsgált kódszó felső bájtjának beolvasása a kódmemóriából
			MOV R7, A ; (RB1) aktuálisan vizsgált kódszó felső bájtjának eltárolása az R7 regiszterben

			CLR RS0 ; 0-s regiszter bankra váltás
			CLR RS1

			;//////////////////////////////////////BELSŐ CIKLUS KEZDETE////////////////////////////////////////////////////

			SETB RS0 ; 1-es regiszterbankra váltás
			CLR RS1

			MOV A, R5 ; (RB1) topiteráció aktuális indexének másolása (aktuálisan vizsgált kódszó felső bájtja)
			MOV R4, A
			INC R4 ; (RB1) szubiteráció (abszolút)indexének növelése (aktuálisan vizsgált kódszót követő kódszó alsó bájtja)

			CLR RS0 ; 0-s regiszter bankra váltás
			CLR RS1

			MOV A, R0 ; szubiterációs tömb méretének eltárolása az R3 regiszterben
			MOV R3, A

Sub_Iter:		SETB RS0 ; 1-es regiszter bankra váltás
			CLR RS1

			MOV A, R4 ; (RB1) a szubiteráció aktuális (abszolút)indexének akkumulátorba töltése a bázisregiszter + indexregiszteres címzéshez
			INC R4 ; (RB1) a szubiteráció (abszolút)indexének növelése

			CLR RS0 ; 0-s regiszter bankra váltás
			CLR RS1

			MOVC A, @A+DPTR ; szubiteráció aktuális kódszó alsó bájtjának beolvasása a kódmemóriából
			MOV R4, A ; szubiteráció aktuális kódszó alsó bájtjának eltárolása az R4 regiszterben

			SETB RS0 ; 1-es regiszter bankra váltás
			CLR RS1

			MOV A, R4 ; (RB1) a szubiteráció aktuális (abszolút)indexének akkumulátorba töltése a bázisregiszter + indexregiszteres címzéshez

			CLR RS0 ; 0-s regiszter bankra váltás
			CLR RS1

			MOVC A, @A+DPTR ; szubiteráció aktuális kódszó felső bájtjának beolvasása a kódmemóriából
			MOV R5, A ; szubiteráció aktuális kódszó felső bájtjának eltárolása az R5 regiszterben

			; Alsó bájtok Hamming távolság vizsgálatának előkészítése
			MOV R2, #00h; aktuális Hamming távolságot tartalmazó regiszter nullázása
			MOV R1, #08h; vizsgálandó alsó bájt helyiértékek darabszámának eltárolása R1 regiszterben

			SETB RS0 ; 1-es regiszter bankra váltás
			CLR RS1

			MOV A, R6 ; (RB1) aktuálisan vizsgált kódszó alsó bájtjának akkumulátorba töltése

			CLR RS0 ; 0-s regiszter bankra váltás
			CLR RS1

			XRL A, R4 ; XOR művelet az aktuálisan vizsgált kódszó és a szubiteráció aktuális elemének alsó bájtjain (alsó bájtok hamming távolságának számítása)

			; Alsó bájtok Hamming távolságának számítása
LGet_Bit:		RRC A ; aktuális legalsó bit rotálása CARRY flagbe az érték vizsgálathoz
			JNC LZero_Bit ; 0 vagy 1 szerepel az aktuális helyiértéken ?
			INC R2 ; aktuális Hamming távolságot tartalmazó regiszter értékének növelése 1-es bit esetén
LZero_Bit:		DJNZ R1, LGet_Bit ; hátra lévő vizsgálandó helyiértékek számának ellenőrzése

			; Felső bájtok Hamming távolság vizsgálatának előkészítése
			MOV R1, #08h; vizsgálandó felső bájt helyiértékek darabszámának eltárolása R1 regiszterben

			SETB RS0 ; 1-es regiszter bankra váltás
			CLR RS1

			MOV A, R7 ; (RB1) aktuálisan vizsgált kódszó felső bájtjának akkumulátorba töltése

			CLR RS0 ; 0-s regiszter bankra váltás
			CLR RS1

			XRL A, R5 ; XOR művelet az aktuálisan vizsgált kódszó és a szubiteráció aktuális elemének felső bájtjain (felső bájtok Hamming távolságának számítása)

			; Felső bájtok Hamming távolságának számítása
HGet_Bit:		RRC A ; aktuális legalsó bit rotálása CARRY flagbe az érték vizsgálathoz
			JNC HZero_Bit ; 0 vagy 1 szerepel az aktuális helyiértéken ?
			INC R2 ; aktuális Hamming távolságot tartalmazó regiszter értékének növelése 1-es bit esetén
HZero_Bit:		DJNZ R1, HGet_Bit ; hátra lévő vizsgálandó helyiértékek számának ellenőrzése

			CLR 0D7h ; CY flag 0-ba állítása (PSW bitjei direkt címzéssel állíthatóak) SUBB művelet elvégzése előtt (SUBB a CY-t is kivonja az akkumulátorból, mi most ezt nem szeretnénk)
			;CLR C ; CY flag törlése (1 gépi ciklus, rövidebb)
			MOV A, R2 ; aktuális Hamming távolságot tartalmazó regiszter értékének akkumulátorba töltése
			SUBB A, R6 ; aktuális Hamming távolság és az eddigi legkisebb Hamming távolság különbsége
			JNC Next_Index ; ha az aktuális Hamming távolság nagyobb vagy egyenlő, mint az eddigi legkisebb Hamming távolság, akkor utóbbi értékét változatlanul hagyjuk
			MOV A, R2 ; ha az aktuális Hamming távolság kisebb, mint az eddigi legkisebb Hamming távolság, akkor utóbbi értékét felülírjuk
			MOV R6, A ;

Next_Index:		SETB RS0 ; 1-es regiszter bankra váltás
			CLR RS1

			INC R4; (RB1) a szubiteráció (abszolút)indexének növelése, hogy ha ugrunk

			CLR RS0 ; 0-s regiszter bankra váltás
			CLR RS1

			DJNZ R3, Sub_Iter ; tömb végének ellenőrzése

			;///////////////////////////////////////BELSŐ CIKLUS VÉGE//////////////////////////////////////////////////////

			SETB RS0 ; 1-es regiszter bankra váltás
			CLR RS1

			INC R5 ; a topiteráció indexének növelése, hogy ha ugrunk Top_Iter-re, akkor már a megfelelő top_index álljon rendelkezésre

			CLR RS0 ; 0-s regiszter bankra váltás
			CLR RS1

			DJNZ R0, Top_Iter ; tömb "végének" ellenőrzése

			USING 1; használt regiszterbank (RB1) kiválasztása POP művelethez (regiszterek miatt)

			POP AR4 ; R4 regiszter stackből visszaállítása
			POP AR5 ; R5 regiszter stackből visszaállítása
			POP AR6 ; R6 regiszter stackből visszaállítása
			POP AR7 ; R7 regiszter stackből visszaállítása

			USING 0 ; használt regiszterbank (RB0) kiválasztása POP művelethez (regiszterek miatt)

			POP AR0 ; R0 regiszter stackből visszaállítása
			POP AR1 ; R1 regiszter stackből visszaállítása
			POP AR2 ; R2 regiszter stackből visszaállítása
			POP AR3 ; R3 regiszter stackből visszaállítása
			POP AR4 ; R4 regiszter stackből visszaállítása
			POP AR5 ; R5 regiszter stackből visszaállítása

			POP ACC ; akkumulátor stackből visszaállítása
			POP PSW ; PSW stackből visszaállítása

			RET ; visszatérés a szubrutinból

			END ; program vége
