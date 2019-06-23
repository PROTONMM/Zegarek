"# ZEGAREK"
Na kanale YT, podczas livestreamu OSDev #4, Gynvael Coldwind zorganizował konkurs na program, szczegóły:

    KONKURS (tym razem skillowy)
    DO: 12.06.2016 23:59
    Napisz efekt graficzny:
    - działający w trybie tekstowym
    - działający jako bootloader
    - zajmujący max 512 bajtów (stage1 ;>)
    - działający minimum pod Bochs
    Nagroda: gift card 100 GBP na amazon.co.uk



Więcej informacji: http://gynvael.coldwind.pl/?id=609

Napisałem programik przedstawiający przesuwające się paski ZX Spectrum, wyświetlający adres: HTTP://MICROGEEK.EU, wyświetlający datę i godzinę oraz wykorzystujący takie mechanizmy:

- odczyt godziny i daty z RTC
- wykorzystanie przerwania IRQ0 (18.2 razy na sekundę) do animacji
- wykorzystanie bufora obrazu
- kopiowanie obszarów pamięci (rep movsw)
- korzystanie z różnych segmentów pamięci


Przedstawienie prac i wynik konkursu na YT.
https://www.youtube.com/watch?v=4gWVPkrv8ts

Przyznam że było bardzo dużo świetnych prac, zachęcam do obejrzenia filmiku na YT, można się zdziwić ile można zrobić w 512 bajtach. 
