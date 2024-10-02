package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	tele "gopkg.in/telebot.v3"
)

var clusterID string = os.Getenv("K8S_CLUSTER_ID")
var k8sYcEndpoint string = "https://mks.api.cloud.yandex.net/managed-kubernetes/v1/clusters/"
var ycJwt string = os.Getenv("YC_SA_JST")
var allowedUsers []int64
var ycIamToken string = getIAMToken()

func init() {
	envAllowedUser := os.Getenv("ALLOWED_USER_ID")

	allowedUser, err := strconv.ParseInt(envAllowedUser, 10, 64)
	if err != nil {
		log.Println("Something went wrong during converting data types:", err)
		return
	}

	allowedUsers = []int64{
		allowedUser,
	}
}

func isAllowedUser(userID int64) bool {
	for _, id := range allowedUsers {
		if id == userID {
			return true
		}
	}
	return false
}

func getIAMToken() string {
	// jot := signedToken()
	// fmt.Println(jot)
	resp, err := http.Post(
		"https://iam.api.cloud.yandex.net/iam/v1/tokens",
		"application/json",
		strings.NewReader(fmt.Sprintf(`{"jwt":"%s"}`, ycJwt)),
	)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		panic(fmt.Sprintf("%s: %s", resp.Status, body))
	}
	var data struct {
		IAMToken string `json:"iamToken"`
	}
	err = json.NewDecoder(resp.Body).Decode(&data)
	if err != nil {
		panic(err)
	}
	return data.IAMToken
}

func start_k8s_cluster() string {
	var reqURL string = (k8sYcEndpoint) + (clusterID) + ":start"
	req, err := http.NewRequest("POST", reqURL, nil)
	if err != nil {
		log.Fatal("Error while creating Request: ", err)
	}

	req.Header.Add("Authorization", "Bearer "+ycIamToken)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal("Error while sending request:", err)
	}
	defer resp.Body.Close()

	log.Println("Response Status", resp.Status)

	return "Start k8s-cluster: " + (clusterID) + "\n"
}

func stop_k8s_cluster() string {
	var reqURL string = (k8sYcEndpoint) + (clusterID) + ":stop"
	req, err := http.NewRequest("POST", reqURL, nil)
	if err != nil {
		log.Fatal("Error while creating Request: ", err)
	}

	req.Header.Add("Authorization", "Bearer "+ycIamToken)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal("Error while sending request:", err)
	}
	defer resp.Body.Close()

	log.Println("Response Status", resp.Status)

	return "Stop k8s-cluster: " + (clusterID) + "\n"
}

func main() {
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-quit
		log.Println("The bot is stopped")
		os.Exit(0)
	}()

	pref := tele.Settings{
		Token:  os.Getenv("TOKEN"),
		Poller: &tele.LongPoller{Timeout: 10 * time.Second},
	}

	bot, err := tele.NewBot(pref)
	if err != nil {
		log.Fatal(err)
		return
	}

	bot.Handle("/start", func(c tele.Context) error {
		user := c.Sender()
		userID := user.ID

		if !isAllowedUser(userID) {
			return c.Send("Sorry, you don't have access to this bot.")
		}

		username := user.Username
		message := "Hello, " + string(username) + "! Nice to meet you!\n" + "Your ID is " + strconv.FormatInt(userID, 10) + "\n"

		return c.Send(message)
	})

	bot.Handle("/start_k8s_cluster", func(c tele.Context) error {
		user := c.Sender()
		userID := user.ID

		if !isAllowedUser(userID) {
			return c.Send("Sorry, you don't have access to this bot.")
		}

		message := start_k8s_cluster()
		return c.Send(message)
	})

	bot.Handle("/stop_k8s_cluster", func(c tele.Context) error {
		user := c.Sender()
		userID := user.ID

		if !isAllowedUser(userID) {
			return c.Send("Sorry, you don't have access to this bot.")
		}

		message := stop_k8s_cluster()
		return c.Send(message)
	})

	log.Println("The bot is running")
	bot.Start()
}
