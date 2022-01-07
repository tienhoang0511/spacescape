import 'package:flutter/material.dart';

import 'settings_menu.dart';
import 'select_spaceship.dart';

// Represents the main menu screen of Spacescape, allowing
// players to start the game or modify in-game settings.
class MainMenu extends StatelessWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // backgroundColor: Colors.red,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/images/stars1.png', width: size.width, height: size.height, fit: BoxFit.fill,),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game title.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50.0),
                  child: Text(
                    'Spacescape',
                    style: TextStyle(
                      fontSize: 50.0,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 20.0,
                          color: Colors.white,
                          offset: Offset(0, 0),
                        )
                      ],
                    ),
                  ),
                ),

                // Play button.
                SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: ElevatedButton(
                    onPressed: () {
                      // Push and replace current screen (i.e MainMenu) with
                      // SelectSpaceship(), so that player can select a spaceship.
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const SelectSpaceship(),
                        ),
                      );
                    },
                    child: Text('Play'),
                  ),
                ),

                // Settings button.
                SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsMenu(),
                        ),
                      );
                    },
                    child: Text('Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
