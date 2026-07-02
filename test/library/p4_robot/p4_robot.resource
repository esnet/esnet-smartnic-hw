*** Settings ***
Library  p4_robot.Library  ${P4_HW_ENV}

*** Keywords ***
P4 Counter Packets Equal
    [Arguments]  ${expected_val}  ${counter_name}  ${counter_index}
    ${counter}  P4 Read Counter  ${counter_name}  ${counter_index}
    ${actual_val}  Set Variable  ${counter.packets}
    Should Be Equal As Integers  ${actual_val}  ${expected_val}  ${counter_name} @ ${counter_index}: actual ${actual_val} != expected ${expected_val}

P4 Register Equal
    [Arguments]  ${expected_val}  ${register_name}  ${register_index}
    ${register}  P4 Register Read  ${register_name}  ${register_index}
    Should Be Equal As Integers  ${register}  ${expected_val}  ${register_name} @ ${register_index}: actual ${register} != expected ${expected_val}

P4 Metadata Equal
    [Arguments]  ${expected_val}  ${meta}  ${k0}  ${k1}

    Dictionary Should Contain Key  ${meta}  ${k0}
    ${v0}  Get From Dictionary  ${meta}  ${k0}

    Dictionary Should Contain Key  ${v0}  ${k1}
    ${v1}  Get From Dictionary  ${v0}  ${k1}

    Should Be Equal As Integers  ${v1}  ${expected_val}  ${k1} is ${v1} but should be ${expected_val}

