
pragma solidity ^0.8.0;
// Der pragma-Ausdruck gibt die Solidity-Version an, mit der der Smart Contract kompiliert werden soll.

contract GameFactory {
    address[] public deployedGames;
    // Eine öffentliche Array-Variable, um die Adressen der bereitgestellten Spiele zu speichern.

    function createGame(uint256 _entryFee, uint256 _prizePool) public {
        address newGame = address(new Game(msg.sender, _entryFee, _prizePool));
        // Erstellt eine neue Instanz des Spiels und speichert deren Adresse.
        // Die Adresse des Aufrufers (Manager) wird als Argument übergeben.
        // _entryFee und _prizePool sind die Parameter, die für das Spiel festgelegt werden.

        deployedGames.push(newGame);
        // Fügt die Adresse des neuen Spiels der Liste der bereitgestellten Spiele hinzu.
    }

    function getDeployedGames() public view returns (address[] memory) {
        return deployedGames;
        // Gibt die Adressen aller bereitgestellten Spiele zurück.
    }
}

contract Game {
    struct Player {
        address payable playerAddress;
        uint256 number;
    }
    // Eine Struktur, um Informationen über einen Spieler zu speichern.

    address public manager;
    // Die Adresse des Managers (der Person, die das Spiel erstellt hat).

    uint256 public entryFee;
    uint256 public prizePool;
    uint256 public winnerReward;
    uint256 public serviceFee;
    uint256 public winningNumber;
    bool public gameEnded;
    // Verschiedene öffentliche Variablen, um Spielinformationen zu speichern.

    Player[] public players;
    // Eine öffentliche Array-Variable, um Informationen über alle Spieler zu speichern.

    //manager:
    //    Diese Variable repräsentiert die Adresse des Managers oder des Erstellers des Spielvertrags.
    //    Der Manager ist derjenige, der das Spiel initiiert, indem er den Vertrag bereitstellt und die Eintrittsgebühr und den Preispool festlegt.
    //    Der Manager verfügt über besondere Berechtigungen im Vertrag, wie z.B. das Beenden des Spiels und das Abheben von Servicegebühren.

    //entryFee:
    //    Diese Variable bestimmt die Menge an Tokens, die Spieler zahlen müssen, um am Spiel teilzunehmen.
    //    Sie repräsentiert die Kosten für einen Spieler, um am Spiel teilzunehmen und seine Vermutung abzugeben.
    //    Die Eintrittsgebühr wird typischerweise vom Manager festgelegt, wenn der Spielvertrag erstellt wird.

    //prizePool:
    //    Diese Variable repräsentiert die Gesamtmenge an Tokens, die aus den Eintrittsgebühren aller Spieler gesammelt wird.
    //    Es ist der Pool von Geldern, aus dem die Gewinner des Spiels ihre Belohnungen erhalten.
    //    Der Preispool wächst, wenn sich mehr Spieler dem Spiel anschließen, indem sie die Eintrittsgebühr zahlen.
    constructor(address _manager, uint256 _entryFee, uint256 _prizePool) {
        manager = _manager;
        entryFee = _entryFee;
        prizePool = _prizePool;
        serviceFee = _prizePool / 10; // 10% service fee
        // Der Konstruktor, der beim Erstellen eines neuen Spiels aufgerufen wird.
        // Setzt den Manager, Eintrittsgebühr, Preispool und Servicegebühr.
    }

    function enter(uint256 _number) public payable {
        require(msg.value == entryFee, "Incorrect entry fee provided");
        require(!gameEnded, "Game has already ended");
        // Überprüft, ob die richtige Eintrittsgebühr bezahlt wurde und das Spiel nicht beendet ist.

        players.push(Player(payable(msg.sender), _number));
        // Fügt den Spieler zur Liste der Spieler hinzu.
    }

    function endGame() public restricted {
        require(!gameEnded, "Game has already ended");
        // Überprüft, ob das Spiel noch nicht beendet ist.

        uint256 totalNumber;
        for (uint256 i = 0; i < players.length; i++) {
            totalNumber += players[i].number;
        }
        // Berechnet die Gesamtsumme der eingereichten Zahlen.

        uint256 averageNumber = totalNumber / players.length;
        winningNumber = (averageNumber * 2) / 3;
        if (winningNumber == 0) {
            winningNumber = 1; // Ensure non-zero winning number
        }
        // Berechnet die Gewinnzahl basierend auf dem Durchschnitt der eingereichten Zahlen.

        uint256 closestNumberDiff = type(uint256).max;
        address payable winner;

        for (uint256 i = 0; i < players.length; i++) {
            uint256 diff = players[i].number > winningNumber ? players[i].number - winningNumber : winningNumber - players[i].number;
            if (diff < closestNumberDiff) {
                closestNumberDiff = diff;
                winner = players[i].playerAddress;
            } else if (diff == closestNumberDiff) {
                if (uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.chainid, i))) % 2) == 0) {
                    winner = players[i].playerAddress;
                }
            }
        }
        // Bestimmt den Gewinner basierend auf der Differenz zwischen ihrer Zahl und der Gewinnzahl.
        // Wenn es mehrere Spieler mit der gleichen Differenz gibt, wird ein Zufallsmechanismus verwendet.

        winnerReward = prizePool - serviceFee;
        winner.transfer(winnerReward);
        payable(manager).transfer(serviceFee);
        // Überweist dem Gewinner den Preis und dem Manager die Servicegebühr.

        gameEnded = true;
        // Setzt das Spiel als beendet.
    }

    modifier restricted() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }
    // Ein Modifier, der sicherstellt, dass nur der Manager bestimmte Funktionen aufrufen kann.
}