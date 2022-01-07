import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:spacescape/widgets/overlays/game_over_menu.dart';

import '../game/game.dart';
import '../widgets/overlays/pause_button.dart';
import '../widgets/overlays/pause_menu.dart';

SpacescapeGame _spacescapeGame = SpacescapeGame();

// This class represents the actual game screen
// where all the action happens.
class GamePlay extends StatelessWidget {
  const GamePlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WillPopScope(
          onWillPop: () async => false,
          child: GameWidget(
            game: _spacescapeGame,
            // Initially only pause button overlay will be visible.
            initialActiveOverlays: [PauseButton.ID],
            overlayBuilderMap: {
              PauseButton.ID: (BuildContext context, SpacescapeGame gameRef) =>
                  PauseButton(
                    gameRef: gameRef,
                  ),
              PauseMenu.ID: (BuildContext context, SpacescapeGame gameRef) =>
                  PauseMenu(
                    gameRef: gameRef,
                  ),
              GameOverMenu.ID: (BuildContext context, SpacescapeGame gameRef) =>
                  GameOverMenu(
                    gameRef: gameRef,
                  ),
            },
          ),
        ),
      ),
    );
  }
}
