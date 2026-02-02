# 🎯 איך להריץ - מדריך מהיר

## הכי פשוט: הסקריפט החדש! ⭐

```powershell
.\Tests\quick-merge-test.ps1
```

**זהו! הסקריפט עושה הכל:**
- ✅ מפעיל את השרת אוטומטית (אם צריך)
- ✅ מציג את הקבצים שאפשר לאחד
- ✅ שואל אותך מה לאחד
- ✅ מבצע את האיחוד
- ✅ פותח את התוצאה

---

## 📍 **איפה להזין את שמות הקבצים?**

כשהסקריפט ירוץ, הוא יציג:

```
📂 קבצים זמינים בתיקיית הקלט:

   1. document1.docx
   2. image.jpg
   3. report.xlsx
   4. summary.txt

📝 הזן את שמות הקבצים לאיחוד (מופרדים בפסיק):

   דוגמאות:
   • file1.docx,file2.xlsx,file3.jpg
   • document.docx,image.png

   או הזן מספרים: 1,2,3

➤ קבצים: 
```

### **כאן תכתוב אחת מהאופציות:**

**אופציה 1: מספרים** (הכי קל!)
```
➤ קבצים: 1,2,3
```

**אופציה 2: שמות קבצים**
```
➤ קבצים: document1.docx,image.jpg,report.xlsx
```

---

## 🎬 תרחיש שלם

### שלב 1: פתח PowerShell
- לחץ `Win + X`
- בחר "Windows PowerShell"

### שלב 2: נווט לתיקיית הפרויקט
```powershell
cd "C:\Users\nechamao\Documents\POCPdf\Poc_PdfTron"
```

### שלב 3: הרץ את הסקריפט
```powershell
.\Tests\quick-merge-test.ps1
```

### שלב 4: בחר קבצים
```
➤ קבצים: 1,2,3
```

### שלב 5: תן שם (אופציונלי)
```
➤ שם: דוח_מאוחד
```
או פשוט לחץ Enter לשם אוטומטי.

### שלב 6: הקובץ ייפתח אוטומטית! ✨

---

## 🔄 אם משהו לא עובד

### בעיה: "לא נמצאו קבצים"
**פתרון:** העתק קבצים ל-`C:\Temp\Input`

### בעיה: "השרת לא עלה"
**פתרון:** בדוק את חלון השרת שנפתח - תראה שגיאות אדומות

### בעיה: "סקריפט לא רץ"
**פתרון:** 
```powershell
# אפשר הרצת סקריפטים
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 📞 עזרה נוספת

- **מדריך מלא בעברית:** `Tests\מדריך_quick_merge.md`
- **מדריך טכני:** `Tests\MERGE_API_GUIDE.md`
- **סיכום:** `IMPLEMENTATION_SUMMARY.md`

---

## 🚀 קיצורי דרך

### הרצה מהירה עם פרמטרים
```powershell
# אחד קבצים ספציפיים
.\Tests\quick-merge-test.ps1 -Files "file1.docx,file2.jpg,file3.xlsx"

# עם שם מותאם אישית
.\Tests\quick-merge-test.ps1 -Files "file1.docx,file2.jpg" -OutputName "דוח_רבעוני"
```

### אם השרת כבר רץ
```powershell
# הסקריפט הישן - יותר מהיר כשהשרת רץ
.\Tests\testMerge.ps1
```

---

**זהו! פשוט תריץ את הפקודה הראשונה והכל יעבוד! 🎉**

```powershell
.\Tests\quick-merge-test.ps1
```
