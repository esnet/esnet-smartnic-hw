*** Settings ***
Documentation    Basic register tests.
Library          hw.registers.Library
Variables        variables
Test Setup       Testcase Setup       ${dev}
Test Teardown    Testcase Teardown    ${dev}


*** Test Cases ***
FW Bytes to Word Endian Test
    FOR    ${i}    IN RANGE    3
        Endian Check Unpacked to Packed    ${dev}    ${0x11223344}
        Endian Check Unpacked to Packed    ${dev}    ${0x44332211}
    END

FW Word to Bytes Endian Test
    FOR    ${i}    IN RANGE    3
        Endian Check Packed to Unpacked    ${dev}    ${0x44332211}
        Endian Check Packed to Unpacked    ${dev}    ${0x11223344}
    END
