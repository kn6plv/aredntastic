
let send = () => {};
let rightSelection = null;
let channels = null;
const nodes = {};
const me = {};
let textObs;

function Q(selector)
{
    return document.querySelector(selector);
}

function I(id)
{
    return document.getElementById(id);
}

function N(html)
{
    const e = document.createElement("div");
    e.innerHTML = html;
    return e.firstElementChild;
}

function T(text)
{
    const e = document.createElement("div");
    e.innerText = text;
    return e.innerHTML;
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

function nodeExpand(node)
{
    const n = parseInt(node.id.substr(1), 16);
    node.num = n;
    const c = { r: (n >> 16) & 255, g: (n >> 16) & 255, b: n & 255 }; 
    node.bcolor = `rgb(${c.r},${c.g},${c.b})`;
    if ((c.r * 299 + c.g * 587 + c.b * 114) / 1000 > 127.5) {
        node.fcolor = "black";
    }
    else {
        node.fcolor = "white";
    }
    node.rolename = roles[node.role] ?? "?";
    node.logo = node.hw_model == 255 ? "aredn" : "meshtastic";
    return node;
}

function htmlChannel(channel)
{
    const nk = channel.namekey.split(" ");
    return `<div id="${nk[0]}" class="channel ${rightSelection === channel.namekey ? "selected" : ""}" onclick="selectChannel('${channel.namekey}')">
        <div class="n">
            <div class="t">${nk[0]}</div>
            <div class="s">${nk[1]}</div>
        </div>
        <div class="unread">${channel.unread > 0 ? channel.unread : ''}</div>
    </div>`;
}

function htmlNode(node)
{
    return `<div id="${node.id}" class="node ${node.logo}">
        <div class="s" style="color:${node.fcolor};background-color:${node.bcolor}">${node.short_name}</div>
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
    const n = nodes[text.from];
    return `<div id="${text.id}" class="text ${n?.num == me.num ? 'right ' : ''}${n?.logo ? n.logo : ''}">
        <div class="s" style="color:${n?.fcolor};background-color:${n?.bcolor}">${n?.short_name ?? "?"}</div>
        ${n?.logo ? '<div class="logo"></div>' : ''}
        <div class="c">
            <div class="l">${T(n ? n.long_name + " (" + n.id + ")" : "")}</div>
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

function updateChannels(msg)
{
    if (msg) {
        channels = msg.channels;
    }
    Q("#channels").innerHTML = channels.map(c => htmlChannel(c)).join("");
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
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                textObs.unobserve(entry.target);
                const channel = getChannel(msg.namekey);
                channel.unread--;
                Q(`#${msg.namekey.split(" ")[0]} .unread`).innerText = (channel.unread > 0 ? channel.unread : "");
            }
        })
    });
    const channel = getChannel(msg.namekey);
    channel.unread = 0;
    Q(`#${msg.namekey.split(" ")[0]} .unread`).innerText = "";
}

function updateNode(msg)
{
    const n = I(msg.node.id);
    if (n) {
        n.remove(n);
    }
    const node = nodeExpand(msg.node);
    nodes[node.num] = node;
    const nd = N(htmlNode(node));
    requestAnimationFrame(_ => {
        const q = Q("#nodes");
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

function updateUnread(msg)
{
    if ("unread" in msg) {
        Q(`#${msg.namekey.split(" ")[0]} .unread`).innerText = (msg.unread > 0 ? msg.unread : "");
        getChannel(msg.namekey).unread = msg.unread;
    }
}

function updateText(msg)
{
    const t = Q("#texts");
    const atbottom = (t.scrollTop > t.scrollHeight - t.clientHeight - 50);
    const n = t.appendChild(N(htmlText(msg.text)));
    if (atbottom) {
        t.lastElementChild.scrollIntoView({ behavior: "smooth", block: "end", inline: "nearest" });
    }
    else {
        textObs.observe(n);
        const channel = getChannel(msg.namekey);
        channel.unread++;
        Q(`#${msg.namekey.split(" ")[0]} .unread`).innerText = channel.unread;
    }
}

function selectChannel(namekey)
{
    rightSelection = namekey;
    send({ cmd: "texts", namekey: namekey });
    updateChannels();
}

function startup()
{
    const sock = new WebSocket(`ws://aredn-build:4404`);
    sock.addEventListener("open", e => {
        send = (msg) => sock.send(JSON.stringify(msg));
    });
    sock.addEventListener("message", e => {
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
            default:
                break;
        }
    });
}

document.addEventListener("DOMContentLoaded", startup);
