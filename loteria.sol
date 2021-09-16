// SPDX-License-Identifier: MIT
// msg.data (bytes): complete calldata
// msg.gas (uint): remaining gas - deprecated in version 0.4.21 and to be replaced by gasleft()
// msg.sender (address): sender of the message (current call)
// msg.sig (bytes4): first four bytes of the calldata (i.e. function identifier)
// msg.value (uint): number of wei sent with the message

pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract loteria {
    // instancia del contrato token
    ERC20Basic private token;

    // direccion
    address public owner;
    address public contrato;

    // numero de tokens creados
    uint256 totalSupply = 10000;

    // Eventos de compra de tokens
    event CompraDeTokens(address _contrato, uint256 _valor);

    constructor() public {
        // instancia funcione del contrato
        token = new ERC20Basic(totalSupply);

        // propietario que devuelve el saldo
        owner = msg.sender;

        // direccion del tokens
        contrato = address(this);
    }

    //----------------------------- TOKEN ------------------------------------------------------

    // establecer el precio de los tokens
    function PrecioToken(uint256 _numTokens) internal pure returns (uint256) {
        // conversion de tokens a ethers: 1 Token -> 1e18 Ethers
        return _numTokens * (1 ether);
    }

    // Generar mas tokens por la loteria
    function GenerarTokens(uint256 _numTokens) public Unicamente(msg.sender) {
        token.increaseTotalSuply(_numTokens);
    }

    // este es un control para las funciones ejecutables por el profesor
    modifier Unicamente(address _direccion) {
        // requiere que el owner sea el que lo pide
        require(
            _direccion == owner,
            "No tienes permisos para ejecutar esta funcion"
        );
        _;
    }

    // comprar tokens para comprar boletos y tickert para loterias
    function ComprarTokens(uint256 _numTokens) public payable {
        // establcer el precio del token
        uint256 coste = PrecioToken(_numTokens);

        // se requiere que el valor de ether pagado se igual al precio del token
        require(msg.value >= coste, "El precio es mayor al saldo del cliente");

        // diferencia a pagar
        uint256 returnValue = msg.value - coste;

        // tranfenrencia de la diferencia
        msg.sender.transfer(returnValue);

        // obtenemos balance de token diponible
        uint256 Balance = TokensDisponible();

        // Filtro para evaluar el balance
        require(_numTokens <= Balance, "2 - No tienes suficientes tokens");

        // tranferencia de tokens al comprador
        token.transfer(msg.sender, _numTokens);

        emit CompraDeTokens(msg.sender, _numTokens);
    }

    // token disponible para la venta (Token del contrato)
    function TokensDisponible() public view returns (uint256) {
        // le pasamos la direccion del contrato
        return token.balanceOf(contrato);
    }

    // balnce de tokens de una persona
    function MisTokens() public view returns (uint256) {
        return token.balanceOf(msg.sender);
    }

    // Balance de tokens del contrato una persona
    // Devuelve lo numero del token disponible del contrato para en usuario
    // tokens acumulados de la venta de boletos
    function Bote() public view returns (uint256) {
        return token.balanceOf(owner);
    }

    // obtiene el saldo de ether del propietario
    function getOwnerBalance() public view returns (uint256) {
        return owner.balance;
    }

    //----------------------------- Loteria ------------------------------------------------------

    // precio de boletos en tokens
    uint256 public PrecioBoleto = 5;
    // relacion entre persona que compra los boletos y los numero de boletos
    mapping(address => uint256[]) idPersonasBoletos;
    // Relacion necesaria para identificar al ganador
    mapping(uint256 => address) AdnBoletos;
    // numero aleatorio
    uint256 randNonce = 0;
    // boletos generados
    uint256[] boletosGenerados;
    // eventos
    event boletosComprados(uint256, address); // Evento cuando se compra un boleto
    event boletosganador(uint256); // Evento  del ganador
    event tokensDevueltos(address, uint256); // Evento cuando se devuelven los tokens

    function comprarBoleto(uint256 _boletos) public {
        // Precio total de los boletos a comprar
        uint256 precioTotal = _boletos * PrecioBoleto;
        // Filtrado de los tokens a pagar
        require(precioTotal <= MisTokens(), "No tienes suficientes tokens");

        // transferencia de tokens al owner -> bote/premio
        /**
         * el cliente paga la transacion:
            ha sido necesario crear un funcion den ERC20.sol con el nombre de transferenciaLoteria debido a que el caso de
            tranfer o tranferform las direcciones que se escogian para realizar la transacion eran equivocadas
            ya que el msg.sender que recibia el metodo de tranfer y tranferrom era la direccion del contrato y debe ser la 
            direccion de la persona fisica que compra los boletos
         */
        token.transferenciaLoteria(msg.sender, owner, precioTotal);

        /*
         * * lo que esto haria es toma la marca de tiempo now, el msg.sender y un nonce (un numero que solo se utiliza una vez
         para que no ejecutemos dos veces la misma funcion de hash con lo mismo parametros)  en incremento
         luego se utiliza keccak256 para convertir estas entradas d  un hash aleatorio,
         convertir ese hash a un uint y luego lomutilizamos % 10000 para tomar los 4 ultimos digitos
         dando un valor aletorio entre 0 - 9999
        */
        for (uint256 i = 0; i < _boletos; i++) {
            uint256 ramdom = uint256(
                keccak256(abi.encodePacked(now, msg.sender, randNonce))
            ) % 10000;

            // almacenamos los datos de los boletos
            randNonce++;

            // numero de boletos comprados
            idPersonasBoletos[msg.sender].push(ramdom);

            // numero de boletos comprados
            boletosGenerados.push(ramdom);

            // asignacion de adn de boletos para tener un ganador
            AdnBoletos[ramdom] = msg.sender;

            // Emison de evento.
            emit boletosComprados(ramdom, msg.sender);
        }
    }

    // Visualizar el numero de boletos de una personas
    function TusBoletos() public view returns (uint256[] memory) {
        return idPersonasBoletos[msg.sender];
    }

    // Visualizar todos los boletos bendidos
    function boletosVendidos() public view returns (uint256[] memory) {
        return boletosGenerados;
    }

    // Funcion para generar ganador y ingresarle los tokens
    function generarGanador() public Unicamente(msg.sender) {
        // Debe haber boleto comprados para generar un ganador
        require(
            boletosGenerados.length > 0,
            "No tienes boletos para generar ganador"
        );

        // Declaracion de la longitud de array
        uint256 longitud = boletosGenerados.length;

        // aleatoriamente elijo un numero entre 0 y la longitud del array
        uint256 ramdom = uint256(
            uint256(keccak256(abi.encodePacked(now))) % longitud
        );

        // elecion del ganador
        uint256 ganador = boletosGenerados[ramdom];

        // emision del evento ganador
        emit boletosganador(ganador);

        // Recuperar la direccion del ganador
        address ganadorDireccion = AdnBoletos[ganador];

        // tranferir tokens al ganador
        token.transferenciaLoteria(msg.sender, ganadorDireccion, Bote());
    }

    // Devolucion de los tokens
    function DevolverTokens(uint256 _numTokens) public payable {
        // el numero de token a devolver debe ser mayor a 0
        require(_numTokens > 0, "No tienes tokens para devolver");
        // el usuario/cliente debe tener los tokens que desea devolver
        require(_numTokens <= MisTokens(), "No tienes suficientes tokens");
        // 1. el cliente devuelve los tokens
        // 2 l loteria paga los tokens devuelto

        token.transferenciaLoteria(msg.sender, address(this), _numTokens);
        msg.sender.transfer(PrecioToken(_numTokens));

        // emision del evento
        emit tokensDevueltos(msg.sender, _numTokens);
    }
}