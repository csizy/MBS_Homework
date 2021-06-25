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
actual_element:	DS 2 ; 2 bájt adatmemória lefoglalása az aktuálisan vizsgált (16 bites) kódszónak (LITTLE ENDIAN)
top_index: DS 1 ; 1 bájt adatmemória foglalása a topiteráció aktuális indexének
sub_index: DS 1 ; 1 bájt adatmemória foglalása az szubiteráció aktuális indexének
array_size: DS 1 ; 1 bájt adatmemória foglalása az átvett tömb méretének
result: DS 1 ; 1 bájt adatmemória foglalása a szubrutin visszatérési értékének elmentéséhez



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
; a kódszavakat (tömb) a program memóriában (CODE SEGMENT)
; konstansokként helyezzük el.
;---------------------------------------------------------------------------------------------------------------------
ARRAY:	DB 0CDh, 14h, 0A3h, 75h, 04h, 10h, 4Ch, 0E5h,  0BAh,8Bh, 21h, 0FAh ; 6 elemű tömb inicializálása teszteléshez
; ARRAY: [0]: 14CDh, [1]: 75A3h, [2]: 1004h, [3]: 0E54Ch, [4]: 8BBAh, [5]: 0FA21h (LITTLE ENDIAN)

;ARRAY: DB 00h, 00h, 0FFh, 0FFh ; 2 elemű tömb inicializálása teszteléshez
; ARRAY: [0]: 0000h, [1]: 0001h (LITTLE ENDIAN) (Hamming távolság: 16 (10h))

Main:
	CLR IE_EA ; interruptok tiltása watchdog tiltás idejére
	MOV WDTCN,#0DEh ; watchdog timer tiltása
	MOV WDTCN,#0ADh
	SETB IE_EA ; interruptok engedélyezése

	; paraméterek előkészítése a szubrutin híváshoz
	MOV DPTR, #ARRAY ; tömb kezdőcím betöltése DPTR-be, ezt kapja a szubrutin bemenetként
	MOV R7, #06h ; tömb elemszám betöltése R7-be, ezt kapja a szubrutin bemenetként
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
; Bementek:			DPTR - tömb kezdőcíme
;				R7 - tömb elemszáma
;
; Kimenetek:  			R6 - minimális Hamming távolság
;
; Regisztereket módosítja:	A
;				R6, R5, R4, R3, R2, R1 (regiszter bank 0)
;
; Flageket módosítja:		CY, OV, AC
; ----------------------------------------------------------------------------------------------------------------------
Min_Hamming_Distance:

			USING 0 ; használt regiszterbank kiválasztása PUSH művelethez (regiszterek miatt)

			PUSH PSW ; PSW stackre mentése
			PUSH ACC ; akkumulátor stackre mentése

			PUSH AR5 ; R5 regiszter stackre mentése
			PUSH AR4 ; R4 regiszter stackre mentése
			PUSH AR3 ; R3 regiszter stackre mentése
			PUSH AR2 ; R2 regiszter stackre mentése
			PUSH AR1 ; R1 regiszter stackre mentése

			MOV R6, #10h ; minimális Hamming távolságot tároló regiszter inicializálása a legnagyobb távolságra (16 bit esetén ez 16 = 0x10)
			MOV top_index, #00h ; topiteráció indexének 0-ra inicializálása
			MOV array_size, R7 ; tömb méretének eltárolása az array_size változóban, ezt a topiteráció során fokozatosan csökkentjük, R7-et (eredeti érték) változatlanul hagyjuk, mert szükségünk lesz még rá
			DEC array_size ; tömb méretének csökkentése 1-el, hogy ne vizsgáljuk az utolsó elemet önmagával (ekkor 0 lesz a minimális Hamming távolság)

Top_Iter:		MOV A, top_index ; a topiteráió aktuális indexének akkumulátorba töltése a bázisregiszter + indexregiszteres címzéshez
			MOVC A, @A+DPTR ; aktuálisan vizsgált kódszó alsó bájtjának beolvasása a kódmemóriából
			MOV actual_element, A ; aktuálisan vizsgált kódszó alsó bájtjának eltárolása az adatmemóriába (LITTLE ENDIAN)

			INC top_index ; a topiteráció indexének növelése

			MOV A, top_index ; a topiteráció aktuális indexének akkumulátorba töltése a bázisregiszter + indexregiszteres címzéshez
			MOVC A, @A+DPTR ; aktuálisan vizsgált kódszó felső bájtjának beolvasása a kódmemóriából
			MOV actual_element+1, A ; aktuálisan vizsgált kódszó felső bájtjának eltárolása az adatmemóriába (LITTLE ENDIAN)

			;//////////////////////////////////////BELSŐ CIKLUS KEZDETE////////////////////////////////////////////////////

			MOV sub_index, top_index ; topiteráció aktuális indexének másolása (aktuálisan vizsgált kódszó felső bájtja)
			INC sub_index ; szubiteráció (abszolút)indexének növelése (aktuálisan vizsgált kódszót követő kódszó alsó bájtja)
			MOV R3, array_size ; szubiterációs tömb méretének eltárolása az R3 regiszterben

Sub_Iter:		MOV A, sub_index ; a szubiteráció aktuális (abszolút)indexének akkumulátorba töltése a bázisregiszter + indexregiszteres címzéshez
			MOVC A, @A+DPTR ; szubiteráció aktuális kódszó alsó bájtjának beolvasása a kódmemóriából
			MOV R4, A ; szubiteráció aktuális kódszó alsó bájtjának eltárolása az R4 regiszterben

			INC sub_index ; a szubiteráció (abszolút)indexének növelése

			MOV A, sub_index ; a szubiteráció aktuális (abszolút)indexének akkumulátorba töltése a bázisregiszter + indexregiszteres címzéshez
			MOVC A, @A+DPTR ; szubiteráció aktuális kódszó felső bájtjának beolvasása a kódmemóriából
			MOV R5, A ; szubiteráció aktuális kódszó felső bájtjának eltárolása az R5 regiszterben

			; Alsó bájtok Hamming távolság vizsgálatának előkészítése
			MOV R2, #00h; aktuális Hamming távolságot tartalmazó regiszter nullázása
			MOV R1, #08h; vizsgálandó alsó bájt helyiértékek darabszámának eltárolása R1 regiszterben
			MOV A, actual_element ; aktuálisan vizsgált kódszó alsó bájtjának akkumulátorba töltése
			XRL A, R4 ; XOR művelet az aktuálisan vizsgált kódszó és a szubiteráció aktuális elemének alsó bájtjain (alsó bájtok Hamming távolságának számítása)

			; Alsó bájtok Hamming távolságának számítása
LGet_Bit:		RRC A ; aktuális legalsó bit rotálása CARRY flagbe az érték vizsgálathoz
			JNC LZero_Bit ; 0 vagy 1 szerepel az aktuális helyiértéken ?
			INC R2 ; aktuális Hamming távolságot tartalmazó regiszter értékének növelése 1-es bit esetén
LZero_Bit:		DJNZ R1, LGet_Bit ; hátra lévő vizsgálandó helyiértékek számának ellenőrzése

			; Felső bájtok Hamming távolság vizsgálatának előkészítése
			MOV R1, #08h; vizsgálandó felső bájt helyiértékek darabszámának eltárolása R1 regiszterben
			MOV A, actual_element+1 ; aktuálisan vizsgált kódszó felső bájtjának akkumulátorba töltése
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

Next_Index:		INC sub_index; a szubiteráció (abszolút)indexének növelése, hogy ha ugrunk Sub_Iter-re, akkor már a megfelelő sub_index álljon rendelkezésre
			DJNZ R3, Sub_Iter ; tömb végének ellenőrzése

			;///////////////////////////////////////BELSŐ CIKLUS VÉGE//////////////////////////////////////////////////////

			INC top_index ; a topiteráció indexének növelése, hogy ha ugrunk Top_Iter-re, akkor már a megfelelő top_index álljon rendelkezésre
			DJNZ array_size, Top_Iter ; tömb "végének" ellenőrzése

			USING 0 ; használt regiszterbank kiválasztása POP művelethez (regiszterek miatt)
			POP AR1 ; R1 regiszter stackből visszaállítása
			POP AR2 ; R2 regiszter stackből visszaállítása
			POP AR3 ; R3 regiszter stackből visszaállítása
			POP AR4 ; R4 regiszter stackből visszaállítása
			POP AR5 ; R5 regiszter stackből visszaállítása

			POP ACC ; akkumulátor stackből visszaállítása
			POP PSW ; PSW stackből visszaállítása

			RET ; visszatérés a szubrutinból

			END ; program vége



;----------------------------------------------------------------------------------------------------------------------
; Program struktúra
;----------------------------------------------------------------------------------------------------------------------
;a) Include -ok
;b) Szimbólumok importálása
;c) Szimbólumok exportálása
;d) Adat szegmens allokációk
;e) Kódszegmens kiválasztása
;f) Ugrótábla
;g) Kód szegmens allokációk (konstansok)
;h) Assembly függvények
;i) END
