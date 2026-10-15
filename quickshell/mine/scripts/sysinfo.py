#!/usr/bin/env python3
# Informacoes do sistema para o painel Inicio: imprime uma linha JSON por segundo (o Quickshell le pelo stdout).
# Roda so enquanto o painel esta aberto. Sem dependencias alem do Python; a GPU NVIDIA vem do nvidia-smi.
import json, os, platform, shutil, subprocess, sys, time

def read(p, d=""):
    try:
        with open(p) as f:
            return f.read()
    except OSError:
        return d

def cpu_times():
    v = [int(x) for x in read("/proc/stat").split("\n")[0].split()[1:]]
    idle = v[3] + (v[4] if len(v) > 4 else 0)
    return idle, sum(v)

def meminfo():
    m = {}
    for line in read("/proc/meminfo").splitlines():
        k, _, rest = line.partition(":")
        m[k] = int(rest.split()[0]) * 1024 if rest.strip() else 0
    return m

def cpu_temp():
    base = "/sys/class/hwmon"
    try:
        for h in sorted(os.listdir(base)):
            name = read(f"{base}/{h}/name").strip()
            if name in ("coretemp", "k10temp", "zenpower", "cpu_thermal"):
                t = read(f"{base}/{h}/temp1_input").strip()
                if t:
                    return round(int(t) / 1000)
    except OSError:
        pass
    return None

def net_bytes():
    rx = tx = 0
    for line in read("/proc/net/dev").splitlines()[2:]:
        name, _, rest = line.partition(":")
        name = name.strip()
        if name == "lo" or name.startswith(("veth", "docker", "br-", "virbr")):
            continue
        f = rest.split()
        rx += int(f[0]); tx += int(f[8])
    return rx, tx

def disks():
    seen, out = set(), []
    for line in read("/proc/mounts").splitlines():
        dev, mnt, fs = line.split()[:3]
        if fs not in ("ext4", "btrfs", "xfs", "f2fs", "ntfs3", "ntfs", "exfat", "vfat") or dev in seen:
            continue
        if mnt.startswith(("/boot", "/efi", "/var", "/snap")):
            continue
        seen.add(dev)
        try:
            s = os.statvfs(mnt)
        except OSError:
            continue
        total = s.f_blocks * s.f_frsize
        used = total - s.f_bfree * s.f_frsize
        if total > 0:
            out.append({"mount": mnt.replace("\\040", " "), "used": used, "total": total})
    return out

GPU = bool(shutil.which("nvidia-smi"))
def gpu():
    if not GPU:
        return None
    try:
        r = subprocess.run(["nvidia-smi", "--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu", "--format=csv,noheader,nounits"],
                           capture_output=True, text=True, timeout=3)
        n, u, mu, mt, t = [x.strip() for x in r.stdout.strip().split("\n")[0].split(",")]
        return {"name": n, "usage": int(u), "memUsed": int(mu) * 1048576, "memTotal": int(mt) * 1048576, "temp": int(t)}
    except Exception:
        return None

def static():
    model = ""
    for line in read("/proc/cpuinfo").splitlines():
        if line.startswith("model name"):
            model = line.split(":", 1)[1].strip(); break
    distro = ""
    for line in read("/etc/os-release").splitlines():
        if line.startswith("PRETTY_NAME="):
            distro = line.split("=", 1)[1].strip('"')
    return {"cpuModel": model, "cores": os.cpu_count(), "distro": distro, "kernel": platform.release(),
            "wm": os.environ.get("XDG_CURRENT_DESKTOP", ""), "host": platform.node()}

def main():
    st = static()
    idle0, tot0 = cpu_times()
    rx0, tx0 = net_bytes()
    t0 = time.monotonic()
    g, tick = None, 0
    while True:
        time.sleep(1)
        idle1, tot1 = cpu_times()
        rx1, tx1 = net_bytes()
        t1 = time.monotonic()
        dt = max(0.001, t1 - t0)
        cpu = 0 if tot1 == tot0 else round(100 * (1 - (idle1 - idle0) / (tot1 - tot0)), 1)
        m = meminfo()
        if tick % 2 == 0:
            g = gpu()
        out = {
            "cpu": cpu, "cpuTemp": cpu_temp(),
            "memUsed": m.get("MemTotal", 0) - m.get("MemAvailable", 0), "memTotal": m.get("MemTotal", 0),
            "swapUsed": m.get("SwapTotal", 0) - m.get("SwapFree", 0), "swapTotal": m.get("SwapTotal", 0),
            "rx": max(0, (rx1 - rx0) / dt), "tx": max(0, (tx1 - tx0) / dt),
            "load": [round(x, 2) for x in os.getloadavg()],
            "uptime": float(read("/proc/uptime", "0").split()[0]),
            "gpu": g,
        }
        if tick % 10 == 0:
            out["disks"] = disks()
            out["static"] = st
        print(json.dumps(out), flush=True)
        idle0, tot0, rx0, tx0, t0 = idle1, tot1, rx1, tx1, t1
        tick += 1

if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
