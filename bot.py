import telebot
import google.generativeai as genai

# Token bot Telegram
TELEGRAM_TOKEN = "8223719269:AAEJQn_cVVsOr51dPkI4CGrEm7EPWcDa3uo"

# API key Gemini
GEMINI_API_KEY = "AIzaSyDur67O4pATCmMtB1ueT0BcWBh794tOKFY"

# Cấu hình Gemini
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("gemini-1.5-flash")

# Khởi tạo bot Telegram
bot = telebot.TeleBot(TELEGRAM_TOKEN)

@bot.message_handler(commands=['start'])
def welcome(message):
    bot.reply_to(message, "🤖 Xin chào! Mình được tích hợp Gemini AI. Hãy hỏi bất cứ điều gì!")

@bot.message_handler(func=lambda m: True)
def chat_with_gemini(message):
    try:
        response = model.generate_content(message.text)
        reply_text = response.text if response.text else "Mình không biết trả lời sao 😅"
        bot.reply_to(message, reply_text)
    except Exception as e:
        bot.reply_to(message, f"⚠️ Lỗi: {str(e)}")

print("Bot Telegram + Gemini đang chạy...")
bot.polling()