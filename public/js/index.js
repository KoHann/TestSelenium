const root = document.body;

const close = () => {
	document.querySelector(".top-jaw").classList.add("top-jaw-close");
	document.querySelector(".bottom-jaw").classList.add("bottom-jaw-close");
	document.querySelector(".top-img").classList.add("top-img-close");
	document.querySelector(".bottom-img").classList.add("bottom-img-close");
};

const open = () => {
	document.querySelector(".top-jaw").classList.remove("top-jaw-close");
	document.querySelector(".bottom-jaw").classList.remove("bottom-jaw-close");
	document.querySelector(".top-img").classList.remove("top-img-close");
	document.querySelector(".bottom-img").classList.remove("bottom-img-close");
};

const Form = {
	view: () => {
		return m("form#form", {enctype: "multipart/form-data", action: "/parse_xls", method: "post"},
			m(".button.file-button", "Fichier à vérifier", m("input", {type: 'file', name: "uploaded_data"})),
			m("input.button", {type: 'submit'})
		)
	}
};

const App = {
	view: () =>
		m("main",
			m(".title", "Automator"),
			m(".banner",
				m(".robot-icon", m("img", {src: "img/robot/robot_icon_info.png", height: "200"})),
				m(".info-text",
					m("", "Téléchargez ci-dessous votre fiche navette. Je me ferai un plaisir de la vérifier !")
				),
			),
			m(Form),
			m(".jaw.top-jaw",
				m("..title.title-waiting", "Automator"),
				m(".banner.banner-waiting",
					m(".robot-icon.robot-icon-waiting", m("img", {src: "img/robot/robot_icon_waiting_1.png", height: "200"})),
					m(".info-text.info-text-waiting",
						m("", "Alors, alors, laissez moi regarder cela...")
					),
				),
			),
			m("img.jaw-img.top-img", {src: "img/jaw-top.png"}),
			m(".jaw.bottom-jaw"),
			m("img.jaw-img.bottom-img", {src: "img/jaw-bottom.png"})
		)

};


m.mount(root, App);

document.getElementById("form").addEventListener("submit", async (event) => {
	event.preventDefault();
	close();
	await new Promise(resolve => setTimeout(resolve, 1000));

	fetch(event.target.action, {
		method: 'POST',
		body: new FormData(event.target), // event.target is the form
		redirect: 'follow'
	}).then(async (response) => {
		console.log(response);
		if (response.redirected) {
			window.location.href = response.url;
		}
		else if (response.status === 406 || response.status === 415) {
			return response.text();
		}
	}).then(async (resp) => {
		console.log(resp)
		document.querySelector(".info-text").querySelector("div").textContent = resp;
		document.querySelector(".robot-icon").querySelector("img").setAttribute("src", "img/robot/robot_icon_error.png");
		open();
		await new Promise(resolve => setTimeout(resolve, 1000));
	}).catch((error) => {
		console.log(error);
	});
});