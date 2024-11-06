package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"

	"gopkg.in/telebot.v3"
)

func Handler(ctx context.Context, req *http.Request) (string, error) {
	// Get bot token
	token := os.Getenv("TELEGRAM_TOKEN")
	if token == "" {
		return "", fmt.Errorf("TELEGRAM_TOKEN environment variable is required")
	}

	// Create bot instance
	bot, err := telebot.NewBot(telebot.Settings{
		Token: token,
		Poller: &telebot.Webhook{
			Endpoint: &telebot.WebhookEndpoint{PublicURL: "https://d5dusc7jv5ql4rurf3u6.apigw.yandexcloud.net/maintainer-bot"},
		},
	})

	if err != nil {
		return "", fmt.Errorf("Failed to create bot: %v", err)
	}

	// Read request body
	body, err := io.ReadAll(req.Body)
	if err != nil {
		return "", fmt.Errorf("Failed to read request body: %v", err)
	}

	// Logging data from Telegram
	fmt.Print(string(body))

	// Create a variable for the incoming update
	var update telebot.Update

	// Try to parse the request body into telebot.Update
	if err := json.Unmarshal(body, &update); err != nil {
		log.Printf("Failed to parse update: %v", err)
		return "", fmt.Errorf("Failed to parse update: %v", err)
	}

	// Log parsed update for debugging
	log.Printf("Parsed update: %+v", update)

	// Start handler for /start command
	bot.Handle("/start", func(c telebot.Context) error {
		return c.Send("Hello")
	})

	// Processing a single Webhook request
	bot.ProcessUpdate(update)

	// Returning a successful response
	response := map[string]string{
		"message": "Webhook processed",
	}
	responseData, _ := json.Marshal(response)

	return string(responseData), nil
}
