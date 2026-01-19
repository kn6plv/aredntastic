let sock = null;
let send = () => {};
let rightSelection = null;
let channels = null;
let echannels = null;
const nodes = {};
let tests = null;
const me = {};
let textObs;
const xdiv = document.createElement("div");
let updateTextTimeout;
let dropSelection;
let replyid;

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
    xdiv.innerText = text.trim();
    return xdiv.innerHTML;
}

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
    const c = { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
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
    node.logo = node.hw;
    return node;
}

function htmlChannel(channel)
{
    const nk = channel.namekey.split(" ");
    return `<div class="channel ${rightSelection === channel.namekey ? "selected" : ""}" onclick="selectChannel('${channel.namekey}')">
        <div class="n">
            <div class="t">${channel.primary ? "Meshtastic" : nk[0]}</div>
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

function htmlText(namekey, text)
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
    let reply = "";
    if (text.replyid) {
        const key = `:${text.replyid}`;
        const r = texts.findLast(t => t.id.indexOf(key) !== -1);
        if (r) {
            reply = `<div class="r"><div>${T(r.text.replace(/\n/g," "))}</div></div>`;
        }
    }
    const txt = T(text.text);
    let textmsg = null;
    const img = txt.match(/^(http:\/\/[^\.]+\.local\.mesh\/cgi-bin\/apps\/raven\/image\?i=.+)$/);
    if (img && useImage(namekey)) {
        textmsg = `<div class="i"><a target="_blank" href="${img[1]}"><img loading="lazy" src="${img[1]}"></a></div>`;
    }
    else {
        textmsg = '<div class="b"><div class="t">' + txt.replace(/https?:\/\/[^ \t<]+/g, v => `<a target="_blank" href="${v}">${v}</a>`) + '</div><a href="#" class="re" onclick="setupReply(event)">Reply</a></div>';
    }
    return `<div id="${text.id}" class="text ${n.num == me.num ? 'right ' : ''}${n.logo ? n.logo : ''}">
        ${reply}
        <div>
            <div class="s" style="color:${n.colors.fcolor};background-color:${n.colors.bcolor}">${n.short_name}</div>
            ${n?.logo ? '<div class="logo"></div>' : ''}
            <div class="c">
                <div class="l">${T(n.long_name + " (" + n.id + ")")} ${n ? "<div>&nbsp;" + (new Date(1000 * text.when).toLocaleString()) + "</div>" : ''}</div>
                ${textmsg}
            </div>
        </div>
    </div>`;
}

function htmlChannelConfig()
{
    let primary = null;
    const body = echannels.map((e, i) => {
        const ne = echannels[i + 1] || {};
        if (e.primary) {
            primary = e;
            return "";
        }
        return `<form class="c">
            <input value="${e.name}" oninput="typeChannelName(${i}, event.target.value)" required minlength="1" maxlength="11" size="11" placeholder="Name" ${e.readonly ? "readonly" : ""} pattern="[^ ]+">
            <input value="${e.key}" oninput="typeChannelKey(${i}, event.target.value)" required minlength="4" maxlength="43" size="43" placeholder="Key" ${e.readonly ? "readonly" : ""} pattern="[\\-A-Za-z0-9+\\/]*={0,3}">
            <input value="${e.max}" oninput="typeChannelMax(${i}, event.target.value)" required minlength="2" maxlength="4" size="4" placeholder="Count" ${e.readonly ? "readonly" : ""}>
            <div><input ${e.badge ? "checked" : ""} type="checkbox" oninput="typeChannelBadge(${i}, event.target.checked)"></div>
            <div><input ${e.images ? "checked" : ""} type="checkbox" disabled></div>
            <select onchange="genChannelKey(${i}, event.target.value)" ${e.readonly ? "disabled" : ""}>
                <option>new key</option>
                <option>1 byte</option>
                <option>128 bit</option>
                <option>256 bit</option>
            </select>
            <button onclick="rmChannel(${i})" ${e.readonly ? "disabled" : ""}>-</button>
            <button onclick="addChannel(${i})" ${e.readonly && ne.readonly ? "disabled" : ""}>+</button>
        </form>`;
    }).join("");
    return `<div class="config">
        <div class="t">Configure Channels</div>
        <div class="b">
            <div class="ct">
                <div>Name</div>
                <div>ID or Key</div>
                <div>Max messages</div>
                <div>Notify</div>
                <div>Images</div>
            </div>
            <form class="c">
                <input value="Meshtastic" readonly><select onchange="typeChannelName(0, event.target.value)">
                    <option ${primary.name === "ShortTurbo" ? "selected" : ""}>ShortTurbo</option>
                    <option ${primary.name === "ShortSlow" ? "selected" : ""}>ShortSlow</option>
                    <option ${primary.name === "ShortFast" ? "selected" : ""}>ShortFast</option>
                    <option ${primary.name === "MediumSlow" ? "selected" : ""}>MediumSlow</option>
                    <option ${primary.name === "MediumFast" ? "selected" : ""}>MediumFast</option>
                    <option ${primary.name === "LongSlow" ? "selected" : ""}>LongSlow</option>
                    <option ${primary.name === "LongFast" ? "selected" : ""}>LongFast</option>
                    <option ${primary.name === "LongMod" ? "selected" : ""}>LongMod</option>
                    <option ${primary.name === "LongTurbo" ? "selected" : ""}>LongTurbo</option>
                </select>
                <input value="100" readonly>
                <div><input ${primary.badge ? "checked" : ""} type="checkbox" oninput="typeChannelBadge(0, event.target.checked)"></div>
                <div><input type="checkbox" disabled></div>
                <select disabled><option>new key</option></select>
            </form>
            ${body}
        </div>
        <div class="d"><button onclick="doneChannels()">Done</button></div>
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
    const node = nodeExpand(msg.node);
    nodes[node.num] = node;
    const nd = N(htmlNode(node));
    const nl = Q("#nodes");
    if (document.visibilityState == "hidden") {
        const n = I(msg.node.id);
        if (n) {
            nl.removeChild(n);
        }
        nl.insertBefore(nd, nl.firstElementChild);
        nd.scrollIntoView({ behavior: "instant", block: "start", inline: "nearest" });
    }
    else {
        requestAnimationFrame(_ => {
            const n = I(msg.node.id);
            if (nl.firstElementChild === n) {
                nl.replaceChild(nd, n);
            }
            else {
                if (n) {
                    nl.removeChild(n);
                }
                nl.insertBefore(nd, nl.firstElementChild);
                if (nl.scrollTop < 70) {
                    nd.nextSibling.scrollIntoView({ behavior: "instant", block: "start", inline: "nearest" });
                    nd.scrollIntoView({ behavior: "smooth", block: "start", inline: "nearest" });
                }
                else {
                    nl.scrollTop += nd.offsetHeight;
                }
            }
        });
    }
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

function restartTextsObserver(channel)
{
    if (textObs) {
        textObs.disconnect();
    }
    textObs = new IntersectionObserver(entries => {
        let newest = null;
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                textObs.unobserve(entry.target);
                channel.unread.count--;
                if (!newest || entry.time >= newest.time) {
                    newest = entry;
                    channel.unread.cursor = entry.target.id;
                }
            }
        });
        if (newest) {
            Q(channel.element, ".unread").innerText = (channel.unread.count > 0 ? channel.unread.count : "");
            send({ cmd: "catchup", namekey: channel.namekey, id: channel.unread.cursor });
            if (textObs.root.lastElementChild.id === channel.unread.cursor) {
                restartTextsObserver(channel);
            }
        }
    }, { root: Q("#texts") });
}

function updateTexts(msg)
{
    clearTimeout(updateTextTimeout);
    const t = Q("#texts");
    texts = msg.texts;
    t.innerHTML = msg.texts.map(t => htmlText(msg.namekey, t)).join("");
    const channel = getChannel(msg.namekey);
    restartTextsObserver(channel);
    channel.unread = msg.unread;
    if (channel.unread.cursor) {
        I(channel.unread.cursor).scrollIntoView({ behavior: "instant", block: "end", inline: "nearest" });
        for (let txt = t.firstElementChild; txt; txt = txt.nextSibling) {
            if (txt.id === channel.unread.cursor) {
                for (txt = txt.nextSibling; txt; txt = txt.nextSibling) {
                    textObs.observe(txt);
                }
                break;
            }
        }
    }
    else if (t.firstElementChild) {
        const container = t.getBoundingClientRect();
        function onScreen(e)
        {
            const r = e.getBoundingClientRect();
            return r.bottom >= container.top && r.top < container.bottom;
        }
        t.firstElementChild.scrollIntoView({ behavior: "instant", block: "start", inline: "nearest" });
        for (let txt = t.firstElementChild; txt; txt = txt.nextSibling) {
            if (onScreen(txt)) {
                channel.unread.count--;
                channel.unread.cursor = txt.id
            }
            else {
                textObs.observe(txt);
            }
        }
        if (channel.unread.cursor) {
            send({ cmd: "catchup", namekey: channel.namekey, id: channel.unread.cursor });
        }
    }
    Q(channel.element, ".unread").innerText = (channel.unread.count > 0 ? channel.unread.count : "");
}

function updateText(msg)
{
    const t = Q("#texts");
    const atbottom = (t.scrollTop > t.scrollHeight - t.clientHeight - 50);
    texts.push(msg.text);
    const n = t.appendChild(N(htmlText(msg.namekey, msg.text)));
    if (atbottom && document.visibilityState == "visible") {
        t.lastElementChild.scrollIntoView({ behavior: "smooth", block: "end", inline: "nearest" });
        send({ cmd: "catchup", namekey: msg.namekey, id: msg.text.id });
    }
    else {
        textObs.observe(n);
        const channel = getChannel(msg.namekey);
        channel.unread.count++;
        Q(channel.element, ".unread").innerText = channel.unread.count;
    }
}

function updateUnread(msg)
{
    const channel = getChannel(msg.namekey);
    channel.unread = msg.unread;
    Q(channel.element, ".unread").innerText = (channel.unread.count > 0 ? channel.unread.count : "");
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
        clearTimeout(updateTextTimeout);
        updateTextTimeout = setTimeout(_ => Q("#texts").innerHTML = "", 500);
    }
}

function sendMessage(event)
{
    const text = event.target.value;
    if (event.type === "keyup") {
        Q("#post .count").innerText = `${Math.max(0, text.length)}/200`;
    }
    else if (event.key === "Escape") {
        resetPost();
    }
    else if (event.key === "Enter" && !event.shiftKey) {
        event.target.value = "";
        if (text) {
            send({ cmd: "post", namekey: rightSelection, text: text.trim(), replyto: replyid });
        }
        resetPost();
        return false;
    }
    return true;
}

function setupReply(event)
{
    const t = Q(event.target.parentNode, ".t");
    const tt = t.closest(".text");
    replyid = tt.id;
    const p = Q("#post");
    const n = N(`<div class="rt">${t.innerText}</div>`);
    if (p.firstElementChild.nodeName == "DIV") {
        p.firstElementChild.remove();
    }
    p.insertBefore(n, p.firstElementChild);
    const pt = Q(p, "textarea");
    pt.placeholder = "Reply ...";
    pt.focus();
}

function resetPost()
{
    replyid = null;
    const p = Q("#post");
    if (p.firstElementChild.nodeName == "DIV") {
        p.firstElementChild.remove();
    }
    Q(p, "textarea").placeholder = "Message ...";
}

function useImage(namekey)
{
    const channel = getChannel(namekey);
    return channel && !channel.primary;
}

function drag(event)
{
    event.preventDefault();
    if (useImage(rightSelection)) {
        if (event.type === "dragenter") {
            event.target.classList.add("drop");
            event.target.placeholder = "Drop image here ...";
        }
        else {
            event.target.classList.remove("drop");
            event.target.placeholder = "Message ...";
        }
    }
}

function sendDrop(event)
{
    event.preventDefault();
    event.target.classList.remove("drop");
    event.target.placeholder = "Message ...";
    if (!useImage(rightSelection)) {
        return;
    }
    dropSelection = rightSelection;
    const file = event.dataTransfer.files[0];
    switch (file?.type ?? "-") {
        case "image/jpeg":
        case "image/png":
        case "image/gif":
        case "image/svg+xml":
        case "image/webp":
        {
            const reader = new FileReader();
            reader.onload = function()
            {
                const maxWidth = 1024;
                const maxHeight = 768;
                const img = new Image();
                img.onload = function()
                {
                    const canvas = document.createElement('canvas');
                    if (img.width > img.height) {
                        if (img.width > maxWidth) {
                            canvas.width = maxWidth;
                            canvas.height = img.height * maxWidth / img.width;
                        }
                        else {
                            canvas.width = img.width;
                            canvas.height = img.height;
                        }
                    }
                    else {
                        if (img.height > maxHeight) {
                            canvas.width = img.width * maxHeight / img.height;
                            canvas.height = maxHeight;
                        }
                        else {
                            canvas.width = img.width;
                            canvas.height = img.height;
                        }
                    }
                    const context = canvas.getContext('2d');
                    context.imageSmoothingEnabled = true;
                    context.drawImage(img, 0, 0, canvas.width,  canvas.height);
                    canvas.toBlob(blob => {
                        event.target.placeholder = "Uploading image ...";
                        send(blob);
                    }, "image/jpeg", 0.9);
                }
                img.src = reader.result;
            }
            reader.readAsDataURL(file);
            break;
        }
        default:
            break;
    }
}

function openChannelConfig()
{
    if (rightSelection !== "channel-config") {
        rightSelection = "channel-config";
        echannels = [];
        channels.forEach((c, i) => {
            const nk = c.namekey.split(" ");
            echannels.push({
                name: nk[0],
                key: nk[1],
                primary: c.primary,
                readonly: i < 2,
                max: c.unread.max,
                badge: c.unread.badge,
                images: useImage(c.namekey)
            });
        });
        Q("#texts").innerHTML = htmlChannelConfig();
    }
}

function addChannel(idx)
{
    echannels.splice(idx + 1, 0, { name: "", key: "", max: 100, badge: true, images: true });
    Q("#texts").innerHTML = htmlChannelConfig();
}

function rmChannel(idx)
{
    echannels.splice(idx, 1);
    Q("#texts").innerHTML = htmlChannelConfig();
}

function typeChannelName(idx, value)
{
    echannels[idx].name = value;
}

function typeChannelKey(idx, value)
{
    echannels[idx].key = value;
}

function typeChannelMax(idx, value)
{
    echannels[idx].max = value;
}

function typeChannelBadge(idx, value)
{
    echannels[idx].badge = value;
}

function genChannelKey(idx, value)
{
    function bytesToBase64(bytes)
    {
        return btoa(Array.from(bytes, byte => String.fromCodePoint(byte)).join(""));
    }
    function rand() {
        return Math.floor(Math.random() * 255);
    }
    let key = null;
    switch (value) {
        case "1 byte":
            key = [ rand() ];
            break;
        case "128 bit":
            key = [ rand(), rand(), rand(), rand(), rand(), rand(), rand(), rand() ];
            break;
        case "256 bit":
            key = [ rand(), rand(), rand(), rand(), rand(), rand(), rand(), rand(),
                    rand(), rand(), rand(), rand(), rand(), rand(), rand(), rand() ];
            break;
        default:
            break;
    }
    if (key) {
        echannels[idx].key = bytesToBase64(key);
        Q("#texts").innerHTML = htmlChannelConfig();
    }
}

function doneChannels()
{
    const nchannels = [];
    const channelnames = [];
    echannels.forEach(e => {
        try {
            if (e.name.length >= 1 && e.key.length >= 4 && e.name.search(/[ \t]/) === -1 && atob(e.key) && e.max >= 10 && e.max <= 1000) {
                const namekey = `${e.name} ${e.key}`;
                const channel = getChannel(namekey) || { primary: false, unread: { count: 0, cursor: null, max: 100, badge: true, images: true } };
                channelnames.push({ namekey: namekey, max: e.max, badge: e.badge });
                channel.unread.max = e.max;
                channel.unread.badge = e.badge;
                nchannels.push({ namekey: namekey, primary: channel.primary, unread: channel.unread });
            }
        }
        catch (_) {
        }
    });
    rightSelection = channelnames[0].namekey;
    send({ cmd: "texts", namekey: rightSelection });
    send({ cmd: "newchannels", channels: channelnames });
    updateChannels({ channels: nchannels });
}

function restartup()
{
    if (sock) {
        try {
            if (sock.readyState < 2) {
                sock.close();
            }
        }
        catch (_) {
        }
        sock = null;
        send = () => {};
        setTimeout(startup, 10000);
    }
}

function startup()
{
    sock = new WebSocket(`ws://${location.hostname}:4404`);
    sock.addEventListener("open", _ => {
        send = (msg) => sock.send(msg instanceof Blob ? msg : JSON.stringify(msg));
    });
    sock.addEventListener("close", restartup);
    sock.addEventListener("error", restartup);
    sock.addEventListener("message", e => {
        try {
            const msg = JSON.parse(e.data);
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
                case "uploaded":
                {
                    Q("#post textarea").placeholder = "Message ...";
                    if (useImage(dropSelection)) {
                        const hostname = location.hostname.indexOf(".local.mesh") == -1 ? `${location.hostname}.local.mesh` : location.hostname;
                        send({ cmd: "post", namekey: dropSelection, text: `http://${hostname}/cgi-bin/apps/raven/image?i=${msg.name}` });
                    }
                    break;
                }
                default:
                    break;
            }
        }
        catch (_) {
        }
    });
}

document.addEventListener("DOMContentLoaded", startup);
