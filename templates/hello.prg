/* basic template file for Minigui */
#include "minigui.ch"

    PROCEDURE Main

      DEFINE WINDOW Win_1 ;
        AT 0,0 ;
        WIDTH 400 ;
        HEIGHT 200 ;
        TITLE 'Hello World!' ;
        MAIN 
      END WINDOW

      ACTIVATE WINDOW Win_1

      RETURN
      