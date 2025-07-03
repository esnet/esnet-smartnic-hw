*** Settings ***
Library  p4_robot.Library  ${P4_HW_ENV}

*** Keywords ***
P4 Counter Packets Equal
    [Arguments]  ${expected_val}  ${counter_name}  ${counter_index}
    ${counter}  P4 Read Counter  ${counter_name}  ${counter_index}
    ${actual_val}  Set Variable  ${counter.packets}
    Should Be Equal As Integers  ${actual_val}  ${expected_val}  ${counter_name} @ ${counter_index}: actual ${actual_val} != expected ${expected_val}

