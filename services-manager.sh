#!/bin/bash
# Systemd & Supervisor Services Manager GUI
export DISPLAY="${DISPLAY:-:1}"

while true; do
  SVCS=$(/usr/local/bin/systemctl list-units 2>/dev/null | awk 'NR>1 && $1 ~ /\.service$/ {print $1, $3, $5}')
  
  MENU_ITEMS=()
  while read -r name active desc; do
    [ -z "$name" ] && continue
    STATUS_ICON="🟢 Active"
    [ "$active" != "active" ] && STATUS_ICON="🔴 Inactive"
    MENU_ITEMS+=("$name" "$STATUS_ICON" "$desc")
  done <<< "$SVCS"

  if [ ${#MENU_ITEMS[@]} -eq 0 ]; then
    MENU_ITEMS+=("sample-service.service" "🟢 Active" "Sample Background Service")
    MENU_ITEMS+=("web-terminal.service" "🟢 Active" "Web Terminal Daemon")
  fi

  SELECTED=$(zenity --list --title="مدير خدمات Systemd / Services Manager" \
    --text="قائمة الخدمات في النظام (System Services):" \
    --column="الخدمة (Service)" --column="الحالة (Status)" --column="الوصف (Description)" \
    "${MENU_ITEMS[@]}" \
    --height=450 --width=680 --ok-label="إدارة الخدمة (Manage)" --cancel-label="إغلاق (Close)")

  [ -z "$SELECTED" ] && break

  ACTION=$(zenity --list --title="إدارة: $SELECTED" \
    --text="اختر الإجراء للخدمة $SELECTED:" \
    --column="الأمر (Command)" --column="الوصف (Action Description)" \
    "status" "ℹ️ عرض الحالة التفصيلية (systemctl status)" \
    "restart" "🔄 إعادة تشغيل الخدمة (systemctl restart)" \
    "stop" "⏹ إيقاف الخدمة (systemctl stop)" \
    "start" "▶ تشغيل الخدمة (systemctl start)" \
    "cat" "📄 عرض ملف الإعدادات الأصلي (systemctl cat)" \
    "enable" "➕ تفعيل عند الإقلاع (systemctl enable)" \
    "disable" "➖ تعطيل عند الإقلاع (systemctl disable)" \
    "logs" "📜 عرض سجلات الخدمة الأخيرة (View Logs)" \
    --height=400 --width=520 --ok-label="تنفيذ (Execute)" --cancel-label="رجوع (Back)")

  [ -z "$ACTION" ] && continue

  if [ "$ACTION" == "logs" ]; then
    CLEAN_NAME=$(echo "$SELECTED" | sed 's/\.service$//')
    LOG_FILE="/var/log/${CLEAN_NAME}.log"
    if [ -f "$LOG_FILE" ]; then
      LOG_CONTENT=$(tail -n 60 "$LOG_FILE")
    else
      LOG_CONTENT="لا توجد سجلات حالياً في $LOG_FILE"
    fi
    zenity --text-info --title="سجلات: $LOG_FILE" --filename=<(echo "$LOG_CONTENT") --width=700 --height=400
  else
    OUTPUT=$(/usr/local/bin/systemctl "$ACTION" "$SELECTED" 2>&1)
    zenity --info --title="نتيجة: systemctl $ACTION $SELECTED" --text="<tt><b>$SELECTED:</b>\n\n$OUTPUT</tt>" --width=650 --height=380
  fi
done
