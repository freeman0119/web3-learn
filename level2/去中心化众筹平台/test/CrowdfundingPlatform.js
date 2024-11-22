const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CrowdfundingPlatform", function () {
  let crowdfundingPlatform;
  let projectContract;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async () => {
    // 获取合约工厂和地址
    [owner, addr1, addr2] = await ethers.getSigners();

    // 部署 CrowdfundingPlatform 合约
    const CrowdfundingPlatform = await ethers.getContractFactory("CrowdfundingPlatform");
    crowdfundingPlatform = await CrowdfundingPlatform.deploy();
    await crowdfundingPlatform.initialize(owner.address);

    // 部署 Project 合约
    const Project = await ethers.getContractFactory("Project");
    projectContract = await Project.deploy();
  });

  describe("Deployment", function () {
    it("should initialize with the correct owner", async function () {
      expect(await crowdfundingPlatform.owner()).to.equal(owner.address);
    });
  });

  describe("createProject", function () {
    it("should allow an owner to create a new project", async function () {
      const description = "Test Project 1";
      const goalAmount = ethers.utils.parseEther("1");
      const duration = 3600; // 1 hour

      await expect(crowdfundingPlatform.createProject(description, goalAmount, duration))
        .to.emit(crowdfundingPlatform, "ProjectCreated")
        .withArgs(
          expect.anything(), // project address
          owner.address,
          description,
          goalAmount,
          expect.anything() // deadline (block.timestamp + duration)
        );

      const projects = await crowdfundingPlatform.getProjects();
      expect(projects.length).to.equal(1);
    });

    it("should correctly create a project and store its address", async function () {
      const description = "Test Project 2";
      const goalAmount = ethers.utils.parseEther("2");
      const duration = 86400; // 24 hours

      await crowdfundingPlatform.createProject(description, goalAmount, duration);

      const projects = await crowdfundingPlatform.getProjects();
      const projectAddress = projects[0];

      const Project = await ethers.getContractFactory("Project");
      const project = await Project.attach(projectAddress);

      const projectDescription = await project.description();
      const projectGoal = await project.goalAmount();
      const projectDuration = await project.duration();

      expect(projectDescription).to.equal(description);
      expect(projectGoal).to.equal(goalAmount);
      expect(projectDuration).to.equal(duration);
    });
  });

  describe("Access Control", function () {
    it("should only allow the owner to create projects", async function () {
      const description = "Test Project 3";
      const goalAmount = ethers.utils.parseEther("1");
      const duration = 7200; // 2 hours

      // addr1 尝试创建项目，应当失败
      await expect(
        crowdfundingPlatform.connect(addr1).createProject(description, goalAmount, duration)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
