# Sistemas-Digitais-Calculadora-BCD

## Introdução
O objetivo deste relatório é documentar o desenvolvimento de um sistema em FPGA que realiza as operações de soma e multiplicação de dois números inteiros arbitrários, A e B, com até 4 algarismos cada. Essas operações devem ser obrigatoriamente realizadas no formato BCD (Binary Coded Decimal). Sua visualização se dará por meio de um sistema de interface implementado que será também explicado.

Para sua realização, foram utilizadas:
- Linguagem de programação: VHDL (VHSIC Hardware Description Language) - linguagem de descrição de hardware usada para descrever o comportamento e estrutura de um sistema digital;
- Placa: Spartan-3A/3AN;
- Programa: Oracle Virtual Box.

O desenvolvimento do sistema foi dividido em várias etapas para garantir uma abordagem modular e escalável. Primeiramente, foi criada uma estrutura básica para a geração da soma e do produto de cada par de algarismos em BCD, focando na implementação de somadores e multiplicadores para dígitos individuais. Após validar a funcionalidade para pares de dígitos, a estrutura foi generalizada para operar com números de até 4 algarismos, garantindo a correta propagação de carries e ajustes necessários no formato BCD. Em seguida, foi desenvolvida uma máquina de estado para a leitura dos números a partir de um teclado numérico e a exibição dos resultados em displays apropriados, permitindo a entrada dos números e a visualização dos resultados das operações.

A última etapa envolveu a integração de todos os módulos desenvolvidos, assegurando que trabalhassem de maneira sincronizada. Flags de sincronismo foram utilizadas para coordenar a operação correta dos diversos componentes do sistema. A arquitetura VHDL foi utilizada para descrever o comportamento do sistema, aproveitando a capacidade de síntese em FPGA para criar um circuito digital eficiente e funcional. O desenvolvimento modular não só facilitou a integração dos diferentes componentes, mas também permitiu uma fácil adaptação e escalabilidade do sistema para futuros aprimoramentos e expansões. Este relatório detalha cada uma dessas etapas, incluindo a lógica de implementação, os desafios encontrados e as soluções adotadas, apresentando ao final os resultados obtidos com a implementação e discutindo possíveis melhorias e extensões para o sistema.

