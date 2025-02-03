module.exports = async function({ getNamedAccounts, deployment }) {
	const { deploy, log } = deployment;
	const { deployer } = await getNamedAccounts();

	const raffle = await deploy("Raffle", {
		from: deployer,
		args: [],
		log: true,
		waitConfirmation: 6,
	})
}