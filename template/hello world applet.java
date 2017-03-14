// basic template file for java applet

import java.awt.Graphics;

public class AppletHelloWorld extends java.applet.Applet {
	public void paint(Graphics g) {
		g.drawString("hello world", 10, 10);
	}
}
