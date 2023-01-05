//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.IC = new Pairing.G1Point[](33);
        
        vk.IC[0] = Pairing.G1Point( 
            15097985019885182273328966319183269928033223270332198132792971948336949912563,
            1779931461448472485408474893419606463320155985255899885540413269053525007935
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            19085782824032258323251289607743092366974331902975153617488535712170770479617,
            3554567943213813923756296785485680299779287070177432092190990372854319370081
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            16730712263694943680995412961373887796579516171911069852263199139966138820675,
            4111816051041965045430882286388602609080585397927795589001836303375794051386
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            20951741004430756394405320220045647119423301119093723949618668349913638459175,
            15903988421242011110458189152963749896336614349031743519376777526788131832828
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            13484227881142237839683152441274069404123942936349996916932457321740652320416,
            2342874867800324849764040754386658398680132903231097755910025544905748137247
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            2669298246412254470906492761369940877664213016983813082045706027069240684889,
            8609937962509266360339680068588288116029651750083930288591403185179352376419
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            11403662954727519023203846822759683501601035566637867468658105264127822663040,
            674532790524494440299277599429052214805508246809017165227632423445682175504
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            9764081526576855251104213912792816361324954831846716138928721639558015312455,
            14902412797938675800067625875816711549580204056091644274877096246325199687270
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            9870156699289766354956347144898197604977178197723485863939883427444024837229,
            15069675457277757345190696850740517250402180877458284974191120558540842966398
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            13865278670769154645575609612580465295225933077351161490192430395615138299747,
            17117119642992534994706532833900528487130434973716603286886062853476119607269
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            8236060976064917168897580484493658674205420682378175315303936319605250331234,
            18486914682097657217502543803876229118517140770127303597884945112059805652313
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            19668262925288246644157722443389958510714860427189386940492780412589385154368,
            2443072245214043826613993133674450287631010493961955448421127648514246930779
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            21163395606037063842540324496103720312854320332877290261280169419965715421687,
            18552265295209509203458886091786851210449603891257905274338903714603775984129
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            21501372000313868054122817503054177562408672218370589524044571613545682744505,
            18007376855114542814045927183394780358430548564219856342048071628001116942334
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            1110202019250399607521749782337284095820051833577477649746595097407674888223,
            14916262933042629153594573330916476672983897881500726932111718932348525170115
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            20935448530318729841909690179815848977873595862133610500137957739342197397430,
            10362916600745709825284236759892419020304945973406888870165740996413200762426
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            7585500897279033603610705226537535461447104402363882703247821017410881418942,
            21705809835634007378301470134534219869739284991007506781742907401254641581788
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            13089797506926018299801690160578833440934587622570016398451418852707188497812,
            1112676427721677682510540547795534080560190020620624656961070424164640274074
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            3113373831689311708418040048756939342696196058266973548532182734127194552043,
            6780952603563630252055821543462483999484200985118365389310295718836372033071
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            16103312578838625546223632337403513781517140087503985302040125569077116390881,
            18461257130881443367149671887492771641814003382441946347783837256919554283343
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            10307329784868571652821976779754499440862409878039222438202299594305122596744,
            1390914950730795696219695086715592378066606077832704108304370051521148609358
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            4364679362449834482044245106359061010205654023884926114759888783265786520237,
            15837109234888352272994988021893000733913722465757931100328695904676024078176
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            14367425368155695005464827095494637804429603889625928014466737417624998423117,
            10703204129006751377679547967891792679020879794482691006528413779031251075370
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            2374372620736125589926664586418102468601262233412537412374501219848564771359,
            13285524439926097775933472596937925481522078637902240721493909127165832630955
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            8769193711424387277737609102584384405787007544494669944976153307731294497994,
            8341764793168237417349235112401896966745992185944462250189301575938117274537
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            6806382657489763245549439501227291137704699987839008622490049791227007656288,
            13684979972830230889062071391374093800276694808193203493888453624743264256996
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            9856711488750319298174243272895536682604643163308611629648905557655480340694,
            14896413820071643567634501891598443475392583925303599916832979239048967746837
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            16742088138397743145900547091858086143462226813791070713925536367837706324437,
            13750645560261624151688030655541439009775672109473041575321370157967881925117
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            7657955530599326087986892856465914979435484722986478402044923898129543633205,
            2768650383658770863127138518696833276156683338568664447682204923807786041561
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            20358338542931214048461371499396529407594394596584031501433990272417891155128,
            11213246789712042533523906492315012095088222764095988902388661282012389595042
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            19048441629215332186716377389037284045629544772865045521117286072237791799313,
            16577665732176749061236475624445941009222322755984656233244302395195330059604
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            18620311141184947667766859330877480536455412052052572480586031989870017118550,
            8395854748220651177135020826459586019574909732855168743851681831289636170119
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            12768058286600104205010293368027595049402262757825470768887885596900815181234,
            18008068112192303897179471593393413918174295241595280682005854049321204275704
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[32] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
