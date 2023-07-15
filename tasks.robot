*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             OperatingSystem
Library             OperatingSystem
Library             RPA.Desktop
Library             RPA.Archive


*** Variables ***
${CSV_FILE_NAME}            orders.csv
${CSV_FILE_URL}             https://robotsparebinindustries.com/${CSV_FILE_NAME}
${WEB_URL}                  https://robotsparebinindustries.com/#/robot-order
${OUT_DIR}                  ${CURDIR}${/}output
${OUTPUT_RECEIPT_DIR}       ${OUT_DIR}${/}receipts
${OUTPUT_IMG_DIR}           ${OUT_DIR}${/}screenshots

${order_page_robot_preview_image}       id=robot-preview-image


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order web
    ${orders} =    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview robot
        ${screenshot} =    Take screenshot of the robot image    ${order}[Order number]
        Submit order
        Create receipt PDF with robot preview image    ${order}[Order number]    ${screenshot}
        Order new robot
        
    END
    Create ZIP file of all receipts
    [Teardown]    Close Browser


*** Keywords ***
Get orders
    Download csv file
    ${orders} =    Read table from CSV    ${CSV_FILE_NAME}
    [Return]    ${orders}

    
Open the robot order web
    Open Available Browser    ${WEB_URL}    headless=${True}

Download csv file
    Download    ${CSV_FILE_URL}    overwrite=True

Close the annoying modal
    Click Button    xpath=//button[contains(text(), "OK")]

Fill the form
    [Arguments]    ${order}
    Log    El Número de orden es: ${order}[Order number]    console=True
    Select From List By Value    xpath=//select[@id="head"]    ${order}[Head]
    Click Button    xpath=//input[@value="${order}[Body]"]
    Input Text    xpath=(//input[@class="form-control"])[1]    ${order}[Legs]
    Input Text    xpath=(//input[@class="form-control"])[2]    ${order}[Address]


Preview robot
    Click Element When Visible    xpath=//button[@id="preview"]
    Wait Until Element Is Visible    xpath=//*[@id="robot-preview-image"]

Take screenshot of the robot image
    [Arguments]    ${order_number}
    Set Local Variable    ${file_path}    ${OUTPUT_IMG_DIR}${/}robot_preview_image_${order_number}.png
    Screenshot    id=robot-preview-image    ${file_path}
    [Return]    ${file_path}

Submit order
    Wait Until Keyword Succeeds    5x    0.5 sec    Save order

Save order
    Click Button    id=order
    Wait Until Element Is Visible    id=receipt
    Wait Until Element Is Visible    id=order-another

Store order receipt as PDF file
    [Arguments]    ${order_number}
    ${receipt_html} =    Get Element Attribute    id=receipt    outerHTML
    Set Local Variable    ${file_path}    ${OUTPUT_RECEIPT_DIR}${/}receipt_${order_number}.pdf
    Html To Pdf    ${receipt_html}    ${file_path}
    RETURN    ${file_path}

Embed robot preview screenshot to receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${image_files} =    Create List    ${screenshot}:align=center
    Add Files To PDF    ${image_files}    ${pdf}    append=True
    Run Keyword And Ignore Error    Close Pdf    ${pdf}

Create receipt PDF with robot preview image
    [Arguments]    ${order_number}    ${screenshot}
    ${pdf} =    Store order receipt as PDF file    ${order_number}
    Embed robot preview screenshot to receipt PDF file    ${screenshot}    ${pdf}
    

Order new robot
    Click Button    xpath=//button[@id="order-another"]
    Wait Until Element Is Visible    id=order

Create ZIP file of all receipts
    ${zip_file_name} =    Set Variable    ${OUT_DIR}${/}compressed_receipts.zip
    Archive Folder With Zip    ${OUTPUT_RECEIPT_DIR}    ${zip_file_name}
    Log    Fin de la Automatización    console=True


    
    