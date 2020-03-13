tic;

%===========================================================%
% DRIVER CODE                                               %
%===========================================================%



toc;

%===========================================================%
% GAME LOGIC                                                %
%===========================================================%

%-----------------%
% Initialize Game %
%-----------------%

% Initialize starting game state
% [In] Null
% [Out] state: Struct containing all state properties
function state = initializeGame()
    % Initialize number of moves and active player
    state.player = 1;
    state.opponent = 2;
    state.moves = 1;
    state.movesNext = [2, 2];
    % Initialize board
    state.tileOwner = zeros(5, 5);
    state.tileWall = zeros(5, 5);
    state.tileDot = zeros(5, 5);
    % Initialize king tile owners
    state.tileOwner(1, 5) = 2;
    state.tileOwner(5, 1) = 1;
    % Initialize number of tiles owned by each player
    state.tileCount = [1, 1];
    % Intialize winner to neither player
    state.winner = 0;
end

%-------------%
% Legal Moves %
%-------------%

% Function to get list of legal moves to
% prevent wasted time trying illegal moves?

% Check if wall can be placed
% [In] x: x-coordinate of targeted tile
% [In] y: y-coordinate of targeted tile
% [Out] isWallable: boolean value, true if wall can be placed at x, y
function isWallable = checkWallable(x, y)
    isWallable = true;
    if x == y
        isWallable = false;
    end
end

%------------------%
% State Transition %
%------------------%

% Returns new state given a state and an action (move)
% [In] state: Struct containing all state properties
% [In] action: Struct containing x, y tile coord and wall direction
% [Out] state: New state after action (move) performed
function state = makeMove(state, action)
    % Extract action values for quick reference
    x = action.x;
    y = action.y;
    wall = action.wall;
    % Extract state values for quick reference
    % Update values in place and set state to equal these values at end
    player = state.player;
    opponent = state.opponent;
    moves = state.moves;
    movesNext = state.movesNext;
    tileOwner = state.tileOwner;
    tileWall = state.tileWall;
    tileDot = state.tileDot;
    tileCount = state.tileCount;
    winner = state.winner;
    
    % If player has no moves left, report error
    if moves < 1
        fprintf("[Illegal Action] Player out of moves");
        return;
    end
    
    % If a player has already won, report error
    if winner ~= 0
        fprintf("[Error] A player has already won");
        return;
    end
    
    % Attempt action based on tile owner
    if tileOwner(x, y) == state.player
        % Current player selected tile owned by self
        % Check if player is trying to place a wall
        if wall == 0
            fprintf("[Illegal Action] Tile already owned by player");
            return;
        end
        % Place currently selected wall if possible
        if x == y % Tiles where x == y are unwallable
            fprintf("[Illegal Action] Tile is unwallable");
            return;
        else
            if tileWall(x, y) == wall
                fprintf("[Illegal Action] Tile already has wall in that direction");
                return;
            else
                tileWall(x, y) = wall;
                moves = moves - 1;
            end
        end
    elseif tileOwner(x, y) == 0
        % Current player selected unowned tile
        % Check if player owns an adjacent tile
        if ~checkAdjacent(tileOwner, tileWall, x, y, player)
            fprintf("[Illegal Action] No valid adjacent tile");
            return;
        else % Player captures unowned tile
            tileOwner(x, y) = player;
            tileDot(x, y) = 1;
            moves = moves - 1;
            tileCount(player) = state_new.tileCount(player) + 1;
        end
    else
        % Current player selected tile owned by opponent
        if ~checkAdjacent(tileOwner, tileWall, x, y, player)
            fprintf("[Illegal Action] No valid adjacent tile");
            return;
        else % Player captures unowned tile
            % Check if opponent tile has a dot
            if tileDot(x, y) == 1 && movesNext(opponent) < 4
                % Award bonus move to opponent for playing on tile with dot
                movesNext(opponent) = movesNext(opponent) + 1;
            end
            tileOwner(x, y) = player;
            tileDot(x, y) = 1;
            tileWall = 0;
            moves = moves - 1;
            tileCount(player) = tileCount(player) + 1;
            tileCount(opponent) = tileCount(opponent) - 1;
            % Check if any tiles were detached from opponent's king
            connectedOpponent = getConnected(tileOwner, opponent);
            connectedTileCount = sum(connectedOpponent == 1);
            if connectedTileCount < tileCount(opponent)
                % Swap owner of detached tiles
                [tileOwner, tileWall, tileDot] = swapOwnership( ...
                    tileOwner, tileWall, tileDot, connectedOpponent, player, opponent);
                % Award bonus move to player for detaching opponent tiles
                if movesNext(player) < 4
                    movesNext(player) = movesNext(player) + 1;
                end
                % Update tile counts for both players
                numSwapped = tileCount(opponent) - connectedTileCount;
                tileCount(player) = tileCount(player) + numSwapped;
                tileCount(opponent) = tileCount(opponent) - numSwapped;
            end
        end
    end
    
    % Check if player has won
    if tileOwner(1, 5) == 1
        if player == 1
            winner = 1;
        else
            fprintf("[Error] Player 1 won, but not player 1's turn");
        end
    end
    if tileOwner(5, 1) == 2
        if player == 2
            winner = 2;
        else
            fprintf("[Error} Player 2 won, but not player 2's turn");
        end
    end
    
    % Determine next player
    nextPlayer = player;
    if moves < 1
        nextPlayer = opponent;
        moves = movesNext(nextPlayer);
        movesNext(nextPlayer) = 2;
        % Remove dot from next player's tiles
        tileDot = clearTileDots(tileOwner, tileDot, nextPlayer);
    end
   
    % Update state to new state values to be returned
    state.player = nextPlayer;
    state.opponent = opponent;
    state.moves = moves;
    state.movesNext = movesNext;
    state.tileOwner = tileOwner;
    state.tileWall = tileWall;
    state.tileDot = tileDot;
    state.tileCount = tileCount;
    state.winner = winner;
end

%--------------------------%
% State Transition Helpers %
%--------------------------%

% Check if valid adjacent tile to capture from
% [In] tileOwner: 5x5 array of tile owners
% [In] tileWall: 5x5 array of tile walls
% [In] x: x-coordinate of targeted tile
% [In] y: y-coordinate of targeted tile
% [In] player: player attempting move
% [Out] isAdjacent: boolean value, true if valid tile adjacent to target
function isAdjacent = checkAdjacent(tileOwner, tileWall, x, y, player)
    % Set to false by default, then check if true
    isAdjacent = false;
    % Target tile does not have wall facing up
    if tileWall(x, y) ~= 1
        % Check if adjacent tile above
        if x ~= 1 && tileOwner(x - 1, y) == player
            isAdjacent = true;
            return;
        end
    end
    % Target tile does not have wall facing right
    if tileWall(x, y) ~= 2
        % Check if adjacent tile to right
        if y ~= 5 && tileOwner(x, y + 1) == player
            isAdjacent = true;
            return;
        end
    end
    % Target tile does not have wall facing down
    if tileWall(x, y) ~= 3
        % Check if adjacent tile below
        if x ~= 5 && tileOwner(x + 1, y) == player
            isAdjacent = true;
            return;
        end
    end
    % Target tile does not have wall facing left
    if tileWall(x, y) ~= 4
        % Check if adjacent tile to left
        if x ~= 5 && tileOwner(x, y - 1) == player
            isAdjacent = true;
            return;
        end
    end
end

% Finds all tiles connected to player's king
% [In] tileOwner: 5x5 array of tile owners
% [In] player: the player whose tiles are being checked 
% [Out] connected: 5x5 boolean array of all tiles connected to player's kings
function connected = getConnected(tileOwner, player)
    % Initialize connected
    connected = zeros(5, 5);
    % Initialize stack
    stack = zeros(1, 100);
    % Push king tile to stack depending on which player
    if player == 1
        stack(1) = 21;
    else
        stack(1) = 5;
    end
    % Find connected tiles using stack
    while ~isempty(stack) && max(stack) > 0
        % Pop first value from stack
        currentTileFlatIndex = stack(1);
        stack = stack(2:end);
        % Determine x, y coordinates from flattened index
        x = floor((currentTileFlatIndex - 1) / 5) + 1;
        y = mod(currentTileFlatIndex - 1, 5) + 1;
        % If tile not already in connected array, check if connected
        if ~ismember(connected, currentTileFlatIndex)
            % Check if tile is connected
            if tileOwner(x, y) == player
                % Tile was connected, set connected value to 1
                connected(x, y) = 1;
                % Check if adjacent tiles are connected
                if currentTileFlatIndex > 5 % Check tile above
                    circshift(stack, 1);
                    stack(1) = currentTileFlatIndex - 5;
                end
                if mod(currentTileFlatIndex, 5) ~= 0 % Check tile to right
                    circshift(stack, 1);
                    stack(1) = currentTileFlatIndex + 1;
                end
                if currentTileFlatIndex < 21 % Check tile below
                    circshift(stack, 1);
                    stack(1) = currentTileFlatIndex + 5;
                end
                if mod(currentTileFlatIndex, 5) ~= 1 % Check tile to left
                    circshift(stack, 1);
                    stack(1) = currentTileFlatIndex - 1;
                end
            end
        end
    end
end

% Swaps ownership of tiles between player and opponent
% [In] tileOwner: 5x5 matrix of tile owners
% [In] tileWall: 5x5 matrix of tile walls
% [In] tileDot: 5x5 matrix of tile dots
% [In] connectedOpponent: 5x5 boolean matrix of opponent's valid tiles
% [In] player: player making current move
% [In] opponent: other player
% [Out] tileOwner: updated 5x5 matrix of tile owners
% [Out] tileWall: updated 5x5 matrix of tile walls
% [Out] tileDot: updated 5x5 matrix of tile dots
function [tileOwner, tileWall, tileDot] = swapOwnership(...
    tileOwner, tileWall, tileDot, connectedOpponent, player, opponent)
    % Check each tile on board and see if swap is needed
    for i = 1:5
        for j = 1:5
            % Check if tile owned by opponent is no longer connected
            if tileOwner(i, j) == opponent && ...
                    ~connectedOpponent(i, j) == opponent
                % Swap tile owner from opponent to player
                tileOwner(i, j) = player;
                % Remove any walls and dots
                tileWall(i, j) = 0;
                tileDot(i, j) = 0;
            end
        end
    end
end

% Clears dots from player's tiles
% [In] tileOwner: 5x5 matrix of tile owners
% [In] tileDot: 5x5 matrix of tile dots
% [In] player: player whose dots will be removed from tiles
% [Out] tileDot: updated 5x5 matrix of tile dots
function tileDot = clearTileDots(tileOwner, tileDot, player)
    % Check each tile on board and see if dot needs to be cleared
    for i = 1:5
        for j = 1:5
            if tileOwner(i, j) == player && tileDot(i, j)
                tileDot(i, j) = 0;
            end
        end
    end
end

%===========================================================%
% REINFORCEMENT LEARNING                                    %
%===========================================================%

