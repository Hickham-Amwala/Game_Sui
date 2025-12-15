# GitHub Copilot Instructions for Godot Game Project

## Project Overview
This is a 2D platformer game built with **Godot 4.5** using **GDScript**.
- **Main Scene:** Defined in `project.godot` (`run/main_scene`).
- **Language:** GDScript (snake_case for functions/vars, PascalCase for classes).

## Architecture & Core Components

### Global State
- **`Global.gd` (Autoload):** Handles persistent data across scenes, specifically player lives (`lives`, `max_lives`).
  - *Pattern:* Use `Global.lives` to access or modify player lives from anywhere.

### Level Management
- **`GameManager` (`scripts/game_manager.gd`):** Manages level-specific logic.
  - **Win Condition:** Requires collecting ALL coins (`score == total_coins`) AND defeating the boss (`is_boss_dead`).
  - **Signals:** Emits `level_unlocked` when win conditions are met.
  - **Access:** Accessed via Unique Name `%GameManager` in player scripts.
  - **Groups:** Uses the "coins" group to count total objectives.

### Player Controller
- **`Player` (`scripts/player.gd`):** Handles movement, combat, and state.
  - **Input:** Uses custom actions defined in Input Map: `jump`, `move left`, `move right`, `attack`.
  - **State:** Boolean flags for `is_attacking`, `is_dead`.
  - **UI Updates:** Currently updates UI elements in `_physics_process` (referencing `CanvasLayer` nodes).

## Coding Conventions

### GDScript Best Practices
- **Node References:** Always use `@onready` variables for node references.
  - *Example:* `@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D`
- **Unique Nodes:** Use Scene Unique Nodes (`%`) for accessing managers or UI from the player.
  - *Example:* `@onready var game_manager = %GameManager`
- **Typing:** Use static typing where possible (`: float`, `: bool`, `-> void`).
- **Comments:** Existing comments are in **Indonesian**. Maintain this style for consistency if modifying existing logic, or use clear English for new complex sections.

### Input Handling
- Use `Input.is_action_just_pressed("action_name")` for triggers (jump, attack).
- Use `Input.get_axis("move left", "move right")` for movement (if applicable) or individual checks.

## Key Workflows

### Creating New Levels
1. Create a new Scene.
2. Add a `GameManager` node (with `%GameManager` unique name).
3. Add `Coin` nodes to the "coins" group.
4. Ensure a Boss or win trigger calls `game_manager.boss_defeated()` or updates the state.

### Debugging
- **Print Debugging:** The project uses `print()` statements extensively for state tracking (e.g., "Nyawa berkurang!", "Target: ...").
- **Scene Running:** Test individual levels by running the specific `.tscn` file.

## Common Patterns
- **Signal Connection:** Prefer connecting signals via editor or `_ready()` for dynamic nodes.
- **Physics:** `move_and_slide()` is used in `CharacterBody2D`. Gravity is applied manually in `_physics_process`.
