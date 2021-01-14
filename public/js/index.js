const root = document.body;

const close = () => {
	document.querySelector(".top-jaw").classList.add("top-jaw-close");
	document.querySelector(".bottom-jaw").classList.add("bottom-jaw-close");
	document.querySelector(".top-img").classList.add("top-img-close");
	document.querySelector(".bottom-img").classList.add("bottom-img-close");
};

const submit = async (e) => {
	e.preventDefault();
	close();
	await new Promise(resolve => setTimeout(resolve, 1000));
	document.getElementById("form").submit();
};

const Form = {
	view: () => {
		return m("form#form", {enctype: "multipart/form-data", action: "/test_bill", method: "post"},
			m("input", {type: 'file', name: "uploaded_data"}),
			m("input", {type: 'submit'})
		)
	}
};

const App = {
	view: () =>
		m("main",
			m(Form),
			m(".sidebar.left-sidebar"),
			m(".sidebar.right-sidebar"),
			m(".jaw.top-jaw"),
			m("img.top-img", {src: "img/jaw-top.png"}),
			m(".jaw.bottom-jaw"),
			m("img.bottom-img", {src: "img/jaw-bottom.png"})
		)

};


m.mount(root, App);

document.getElementById("form").addEventListener("submit", submit)
