#!/data/data/com.termux/files/usr/bin/bash

# --- CU HNH H THNG NRM ---
readonly NRM_VERSION="1.0.2"
readonly CONF_DIR="$HOME/.nrm_config"
readonly MASTER_KEY="$CONF_DIR/master.key"
readonly ADMIN_DB="$CONF_DIR/engineers.db"
readonly AUTH_LOG="$CONF_DIR/auth.log"

# --- TO M TOTP (2FA) THI GIAN THC ---
generate_totp() {
    local secret="NRM_SECRET_$(getprop ro.serialno)"
    local timestamp=$(date +%s)
    local time_step=$((timestamp / 30))
    # To m hash SHA1 da trn secret v bc thi gian
    local hash=$(echo -n "${secret}${time_step}" | openssl dgst -sha1 | awk '{print $2}')
    # Chuyn ði 6 ký t cui ca hash thnh s nguyn v ly 6 ch s
    local otp=$((16#${hash: -6} % 1000000))
    printf "%06d" "$otp"
}

# --- HM KIM TRA TRUY CP (2-FACTOR AUTHENTICATION) ---
authenticate_admin() {
    local current_otp=$(generate_totp)
    printf "[SYSTEM] YU CU XÁC THC 2FA.\n"
    
    # Lp 1: Password h thng
    read -sp "[1/2] Nhp mt khu qun tr: " pass_input; echo
    local stored_pass=$(cat "$MASTER_KEY" 2>/dev/null)
    
    if [[ "$pass_input" != "$stored_pass" ]]; then
        echo "[BÁO ÐNG] Sai mt khu qun tr."; return 1
    fi

    # Lp 2: TOTP (Thi gian thc)
    printf "[2/2] Nhp m OTP (Cp bi thit b): "
    read otp_input
    
    if [[ "$otp_input" != "$current_otp" ]]; then
        echo "[BÁO ÐNG] M OTP không hp l hoc ð ht hn."; return 1
    fi

    echo "[XÁC THC THNH CÔNG]"; return 0
}

# --- GIAO DIN QUN TR VIN ---
admin_panel() {
    clear
    echo "--------------------------------------------------"
    echo "NRM-CORE MANAGER | VERSION: $NRM_VERSION"
    echo "THIT B: $(getprop ro.product.model)"
    echo "--------------------------------------------------"
    echo "1. Cp phép h s k s (.sig)"
    echo "2. Kim tra trng thái tng la mng"
    echo "3. Truy xut nht ký kim toán (Audit Log)"
    echo "4. Thu hi quyn truy cp hin trng"
    echo "5. Ðãng xut"
    echo "--------------------------------------------------"
    read -p "Chn tác v: " choice

    case $choice in
        1) 
            read -p "Nhp ID k s: " eid
            echo "AUTH_SIG_$(date +%Y%m%d)_$eid" > "$CONF_DIR/$eid.sig"
            echo "[$(date)] Ð cp phép cho $eid" >> "$AUTH_LOG"
            echo "Ð to file ch ký ti $CONF_DIR/$eid.sig"
            ;;
        2) 
            echo "--- CÁC KT NI ÐANG HOT ÐNG ---"
            netstat -antp 2>/dev/null | grep "ESTABLISHED"
            ;;
        3) cat "$AUTH_LOG" ;;
        5) exit 0 ;;
        *) admin_panel ;;
    esac
}

# --- KHI CHY ---
mkdir -p "$CONF_DIR"
if [[ ! -f "$MASTER_KEY" ]]; then
    echo "[!] H thng cha ðc thit lp. Vui lng to mt khu: "
    read -s new_pass
    echo "$new_pass" > "$MASTER_KEY"
fi

if authenticate_admin; then
    while true; do admin_panel; read -p "Nhn Enter ð tip tc..."; done
else
    echo "[!] Truy cp b t chi."
    exit 1
fi
