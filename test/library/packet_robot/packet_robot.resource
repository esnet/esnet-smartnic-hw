*** Settings ***
Library  packet_robot.Library

*** Keywords ***

Packet Extend
    [Arguments]  ${base_pkt}  ${keyword}  &{kwargs}
    ${newlayer}=  Run Keyword  ${keyword}  &{kwargs}
    ${pkt}=  Packet Compose  ${base_pkt}  ${newlayer}
    #Packet Log Packets  ${pkt}
    RETURN  ${pkt}

Packet Field Equal
    [Arguments]  ${pkt}  ${layer_name_or_index}  ${field_name}  ${field_expected_value}
    ${layer_fields}  Packet Layer Fields  ${pkt}  ${layer_name_or_index}
    ${field_actual_value}  Set Variable  ${layer_fields}[${field_name}]
    Should Be Equal  ${field_actual_value}  ${field_expected_value}  Layer ${layer_name_or_index} Field ${field_name} is ${field_actual_value} not ${field_expected_value}
    
