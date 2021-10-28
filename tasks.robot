# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.Excel.Files

Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
#Library          RPA.Dialogs
Library           RPA.Robocloud.Secrets
#Library          RPA.Robocorp.Vault


# +
*** Variables ***

${GLOBAL_RETRY_AMOUNT}=    10x
${GLOBAL_RETRY_INTERVAL}=    1s
${order_number}
# -

*** Keywords ***
Get Url From vault and open Robo Website
    ${url}=    Get Secret    credentials
    Log        ${url}
    Open Available Browser      ${url}[robotsparebin]    
    #Click Link  link:Order your robot!
    Click Button    OK


*** Keywords ***
Get orders
    # ${CSV_FILE_URL}=    Get orders.csv URL from User
    #Download        ${CSV_FILE_URL}           overwrite=True
    Download   https://robotsparebinindustries.com/orders.csv   overwrite=True
    ${table}=   Read table from CSV    orders.csv   dialect=excel   header=True
    FOR  ${row}  IN      @{table}
        Log    ${row}
    END
    [Return]    ${table}

*** Keywords ***
#Close The annoying Modal
#    Click Button    OK

*** Keywords ***
Fill The Form
    [Arguments]     ${localrow}
    ${head}=    Convert To Integer    ${localrow}[Head]
    ${body}=    Convert To Integer    ${localrow}[Body]
    ${legs}=    Convert To Integer    ${localrow}[Legs]
    ${address}=     Convert To String    ${localrow}[Address]
    Select From List By Value    id:head    ${head}
    Click Element    id-body-${body}
    Input Text    id:address    ${address}
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input      ${legs}

*** Keywords ***
Preview the robot
    Click Element    id:preview
    Wait Until Element Is Visible    id:robot-preview

*** Keywords ***
Submit the order And Keep Checking Until Success
    Click Element    order
    Element Should Be Visible    xpath://div[@id="receipt"]/p[1]
    Element Should Be Visible    id:order-completion


*** Keywords ***
Submit The Order
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}     Submit the order And Keep Checking Until Success


*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:order-completion
    ${order_number}=    Get Text    xpath://div[@id="receipt"]/p[1]
    #Log    ${order_number}
    ${receipt_html}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
    [Return]    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf

*** Keywords ***
Take a screenshot of the robot
  [Arguments]    ${order_number}
    Screenshot     id:robot-preview    ${CURDIR}${/}output${/}${order_number}.png
    [Return]       ${CURDIR}${/}output${/}${order_number}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}   ${pdf}
    Open Pdf       ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf      ${pdf}

# +
*** Keywords ***
Go to order another robot
        Click Button    order-another


# -

*** Keywords ***
Create Zip Files of Receipts
        Archive Folder With Zip  ${CURDIR}${/}output${/}receipts   ${CURDIR}${/}output${/}receipt.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get Url From vault and open Robo Website
    #Open the robot order website
    
    ${orders}=  Get orders
    FOR  ${row}  IN  @{orders}
        #Close The annoying Modal
        Fill The Form   ${row}
        Preview the robot
        Submit The Order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
        Click Button    OK
    END
    
    Create Zip Files of Receipts
    [Teardown]      Close Browser


