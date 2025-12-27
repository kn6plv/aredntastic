
let send = () => {};
let rightSelection = null;
let channels = null;
const nodes = {};
const me = {};
let textObs;
const xdiv = document.createElement("div");

function Q(a, b)
{
    if (b) {
        return a.querySelector(b);
    }
    else {
        return document.querySelector(a);
    }
}

function I(id)
{
    return document.getElementById(id);
}

function N(html)
{
    xdiv.innerHTML = html;
    return xdiv.firstElementChild;
}

function T(text)
{
    xdiv.innerText = text;
    return xdiv.innerHTML;
}

const roles = {
    0: "Client",
    1: "Client Mute",
    2: "Router",
    3: "Route Client",
    4: "Repeater",
    5: "Tracker",
    6: "Sensor",
    7: "Tak",
    8: "Client Hidden",
    9: "Lost and Found",
    10: "Tak Tracker",
    11: "Router Late",
    12: "Client Base"
};

function getChannel(namekey)
{
    for (let i = 0; i < channels.length; i++) {
        if (channels[i].namekey === namekey) {
            return channels[i];
        }
    }
    return null;
}

function nodeColors(n)
{
    const c = { r: (n >> 16) & 255, g: (n >> 16) & 255, b: n & 255 }; 
    const bcolor = `rgb(${c.r},${c.g},${c.b})`;
    if ((c.r * 299 + c.g * 587 + c.b * 114) / 1000 > 127.5) {
        return { bcolor: bcolor, fcolor: "black" };
    }
    else {
        return { bcolor: bcolor, fcolor: "white" };
    }
}

function nodeExpand(node)
{
    const n = parseInt(node.id.substr(1), 16);
    node.num = n;
    node.colors = nodeColors(n);
    node.rolename = roles[node.role] ?? "?";
    node.logo = node.hw_model == 255 ? "aredn" : "meshtastic";
    return node;
}

function htmlChannel(channel)
{
    const nk = channel.namekey.split(" ");
    return `<div class="channel ${rightSelection === channel.namekey ? "selected" : ""}" onclick="selectChannel('${channel.namekey}')">
        <div class="n">
            <div class="t">${nk[0]}</div>
            <div class="s">${nk[1]}</div>
        </div>
        <div class="unread">${channel.unread.count > 0 ? channel.unread.count : ''}</div>
    </div>`;
}

function htmlNode(node)
{
    return `<div id="${node.id}" class="node ${node.logo}">
        <div class="s" style="color:${node.colors.fcolor};background-color:${node.colors.bcolor}">${node.short_name}</div>
        <div class="logo"></div>
        <div class="m">
            <div class="l">${node.long_name}</div>
            <div class="r">${node.rolename}</div>
            <div class="t">${new Date(1000 * node.lastseen).toLocaleString()}</div>
        </div>
    </div>`;
}

function htmlText(text)
{
    let n = nodes[text.from];
    if (!n) {
        const id = text.from.toString(16);
        n = {
            id: `!${id}`,
            short_name: id.substr(-4),
            long_name: id.substr(-4),
            colors: nodeColors(text.from)
        };
    }
    return `<div id="${text.id}" class="text ${n.num == me.num ? 'right ' : ''}${n.logo ? n.logo : ''}">
        <div class="s" style="color:${n.colors.fcolor};background-color:${n.colors.bcolor}">${n.short_name}</div>
        ${n?.logo ? '<div class="logo"></div>' : ''}
        <div class="c">
            <div class="l">${T(n.long_name + " (" + n.id + ")")} ${n ? new Date(1000 * text.when).toLocaleString() : ''}</div>
            <div class="t">${T(text.text)}</div>
        </div>
    </div>`;
}

function updateMe(msg)
{
    me.num = msg.me.id;
}

function updateNodes(msg)
{
    Q("#nodes").innerHTML = msg.nodes.map(n => {
        n = nodeExpand(n);
        nodes[n.num] = n
        return htmlNode(n);
    }).join("");
}

function updateNode(msg)
{
    const n = I(msg.node.id);
    const node = nodeExpand(msg.node);
    nodes[node.num] = node;
    const nd = N(htmlNode(node));
    requestAnimationFrame(_ => {
        const q = Q("#nodes");
        if (n) {
            n.remove(n);
        }
        q.prepend(nd);
        if (q.scrollTop < 50) {
            nd.nextSibling.scrollIntoView({ behavior: "instant", block: "start", inline: "nearest" });
            nd.scrollIntoView({ behavior: "smooth", block: "start", inline: "nearest" });
        }
        else {
            q.scrollTop += nd.offsetHeight;
        }
    });
}

function updateChannels(msg)
{
    if (msg) {
        channels = msg.channels;
    }
    const q = Q("#channels");
    q.innerHTML = channels.map(c => htmlChannel(c)).join("");
    for (let c = 0; c < channels.length; c++) {
        channels[c].element = q.children[c];
    }
}

function updateTexts(msg)
{
    const t = Q("#texts");
    t.innerHTML = msg.texts.map(t => htmlText(t)).join("");
    t.lastElementChild.scrollIntoView({ behavior: "instant", block: "end", inline: "nearest" });
    if (textObs) {
        textObs.disconnect();
    }
    textObs = new IntersectionObserver(entries => {
        let newest = null;
        const channel = getChannel(msg.namekey);
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                textObs.unobserve(entry.target);
                channel.unread.count--;
                if (!newest || entry.time > newest.time) {
                    newest = entry;
                }
            }
        });
        if (newest) {
            Q(channel.element, ".unread").innerText = (channel.unread.count > 0 ? channel.unread.count : "");
            send({ cmd: "catchup", namekey: msg.namekey, id: newest.target.id });
        }
    });
    const channel = getChannel(msg.namekey);
    channel.unread.count = 0;
    Q(channel.element, ".unread").innerText = "";
    send({ cmd: "catchup", namekey: msg.namekey, id: msg.texts[msg.texts.length - 1].id });
}

function updateUnread(msg)
{
    const channel = getChannel(msg.namekey);
    channel.unread = msg.unread;
    Q(channel.element, ".unread").innerText = (channel.unread.count > 0 ? channel.unread.count : "");
}

function updateText(msg)
{
    const t = Q("#texts");
    const atbottom = (t.scrollTop > t.scrollHeight - t.clientHeight - 50);
    const n = t.appendChild(N(htmlText(msg.text)));
    if (atbottom) {
        t.lastElementChild.scrollIntoView({ behavior: "smooth", block: "end", inline: "nearest" });
        send({ cmd: "catchup", namekey: msg.namekey, id: msg.text.id });
    }
    else {
        textObs.observe(n);
        updateUnread(msg);
    }
}

function selectChannel(namekey)
{
    if (rightSelection === namekey) {
        Q("#texts").lastElementChild.scrollIntoView({ behavior: "smooth", block: "end", inline: "nearest" });
    }
    else {
        rightSelection = namekey;
        send({ cmd: "texts", namekey: namekey });
        updateChannels();
    }
}

function sendMessage(event)
{
    const text = event.target.value;
    if (event.type === "keyup") {
        Q("#post .count").innerText = `${Math.max(0, text.length)}/200`;
    }
    else if (event.key === "Enter" && !event.shiftKey) {
        event.target.value = "";
        if (text) {
            send({ cmd: "post", namekey: rightSelection, text: text.trim() });
        }
        return false;
    }
    return true;
}

function openDialog(html)
{
    if (!Q("#main dialog")) {
        const dialog = document.createElement("dialog");
        dialog.innerHTML = html;
        Q("#main").prepend(dialog);
        dialog.addEventListener("keypress", e => {
            if (e.key === "Escape") {
                dialog.remove();
            }
        });
        dialog.showModal();
    }
}

function openChannelConfig()
{
    openDialog("Channel Config");
}

function startup()
{
    const sock = new WebSocket(`ws://aredn-build:4404`);
    sock.addEventListener("open", e => {
        send = (msg) => sock.send(JSON.stringify(msg));
    });
    sock.addEventListener("message", e => {
        try {
            const msg = JSON.parse(e.data);
            //console.log(msg);
            switch (msg.event) {
                case "me":
                    updateMe(msg);
                    break;
                case "nodes":
                    updateNodes(msg);
                    break;
                case "channels":
                    if (!rightSelection) {
                        rightSelection = msg.channels[0].namekey;
                    }
                    updateChannels(msg);
                    break;
                case "texts":
                    if (rightSelection == msg.namekey) {
                        updateTexts(msg);
                    }
                    else {
                        updateUnread(msg);
                    }
                    break;
                case "node":
                    updateNode(msg);
                    break;
                case "text":
                    if (rightSelection == msg.namekey) {
                        updateText(msg);
                    }
                    else {
                        updateUnread(msg);
                    }
                    break;
                case "catchup":
                    updateUnread(msg);
                    break;
                default:
                    break;
            }
        }
        catch (_) {
        }
    });
}

document.addEventListener("DOMContentLoaded", startup);
