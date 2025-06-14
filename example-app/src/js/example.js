import { SipLinphone } from 'capacitor-sip-linphone';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    SipLinphone.echo({ value: inputValue })
}
