#!/bin/bash

# --- AYARLAR ---
TOKEN="8658208062:AAEfWlEAJ06Tff18ZHl9VckjnTKQ32iAbNA"
SIFRE="linux123"
URL="https://api.telegram.org/bot$TOKEN"
OFFSET=0
YETKILI_ID=""

echo "Bot başlatıldı... (Python ve JQ GEREKTİRMEZ)"

while true; do
    # Mesajları al
    UPDATES=$(curl -s "$URL/getUpdates?offset=$OFFSET&timeout=20")
    
    # OFFSET GÜNCELLEME (JQ olmadan update_id çekme)
    NEW_OFFSET=$(echo "$UPDATES" | grep -oP '"update_id":\K[0-9]+' | tail -n 1)
    if [ ! -z "$NEW_OFFSET" ]; then
        OFFSET=$((NEW_OFFSET + 1))
    fi

    # CHAT_ID ve TEXT Ayıklama
    # Bu kısım her yeni mesajı ham metin üzerinden yakalar
    CHAT_ID=$(echo "$UPDATES" | grep -oP '"chat":{"id":\K[0-9]+' | head -n 1)
    TEXT=$(echo "$UPDATES" | grep -oP '"text":"\K[^"]+' | tail -n 1)

    if [ ! -z "$TEXT" ]; then
        # Yetki Kontrolü
        if [ "$CHAT_ID" != "$YETKILI_ID" ]; then
            if [ "$TEXT" == "$SIFRE" ]; then
                YETKILI_ID="$CHAT_ID"
                curl -s "$URL/sendMessage" -d "chat_id=$CHAT_ID" -d "text=✅ Şifre onaylandı." > /dev/null
            else
                # Sadece şifre girilmediyse uyarı ver (döngü kirliliği olmasın diye)
                curl -s "$URL/sendMessage" -d "chat_id=$CHAT_ID" -d "text=🔐 Şifre girin:" > /dev/null
            fi
        else
            # Komutu çalıştır
            # Telegram'dan gelen metinlerdeki \/ gibi kaçış karakterlerini temizle
            CLEAN_TEXT=$(echo "$TEXT" | sed 's/\\//g')
            
            OUTPUT=$(eval "$CLEAN_TEXT" 2>&1)
            [ -z "$OUTPUT" ] && OUTPUT="İşlem tamam."

            # Sonucu gönder
            curl -s "$URL/sendMessage" -d "chat_id=$CHAT_ID" -d "text=💻 Çıktı:
$OUTPUT" > /dev/null
        fi
    fi

    sleep 1
done
