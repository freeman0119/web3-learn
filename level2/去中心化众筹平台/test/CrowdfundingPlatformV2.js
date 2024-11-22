const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CrowdfundingPlatformV2", function () {
  let crowdfundingPlatformV2;
  let projectContract;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async () => {
    // 获取合约工厂和地址
    [owner, addr1, addr2] = await ethers.getSigners();

    // 部署 CrowdfundingPlatformV2 合约
    const CrowdfundingPlatformV2 = await ethers.getContractFactory("CrowdfundingPlatformV2");
    crowdfundingPlatformV2 = await CrowdfundingPlatformV2.deploy();
    await crowdfundingPlatformV2.initialize(owner.address);

    // 部署 Project 合约
    const Project = await ethers.getContractFactory("Project");
    projectContract = await Project.deploy();
  });

  describe("Deployment", function () {
    it("should initialize with the correct owner", async function () {
      expect(await crowdfundingPlatformV2.owner()).to.equal(owner.address);
    });

    it("should initialize with count as 0", async function () {
      expect(await crowdfundingPlatformV2.count()).to.equal(0);
    });
  });

  describe("createProject", function () {
    it("should allow an owner to create a new project and increment count", async function () {
      const description = "Test Project 1";
      const goalAmount = ethers.utils.parseEther("1");
      const duration = 3600; // 1 hour

      await expect(crowdfundingPlatformV2.createProject(description, goalAmount, duration))
        .to.emit(crowdfundingPlatformV2, "ProjectCreated")
        .withArgs(
          expect.anything(), // project address
          owner.address,
          description,
          goalAmount,
          expect.anything() // deadline (block.timestamp + duration)
        );

      // 检查项目数量是否正确增加
      expect(await crowdfundingPlatformV2.count()).to.equal(1);

      const projects = await crowdfundingPlatformV2.getProjects();
      expect(projects.length).to.equal(1);
    });

    it("should correctly create a project and store its address", async function () {
      const description = "Test Project 2";
      const goalAmount = ethers.utils.parseEther("2");
      const duration = 86400; // 24 hours

      await crowdfundingPlatformV2.createProject(description, goalAmount, duration);

      const projects = await crowdfundingPlatformV2.getProjects();
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
        crowdfundingPlatformV2.connect(addr1).createProject(description, goalAmount, duration)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("count variable", function () {
    it("should increment count when a project is created", async function () {
      // 确保 count 初始值为 0
      expect(await crowdfundingPlatformV2.count()).to.equal(0);

      // 创建第一个项目
      await crowdfundingPlatformV2.createProject("Test Project 1", ethers.utils.parseEther("1"), 3600);
      expect(await crowdfundingPlatformV2.count()).to.equal(1);

      // 创建第二个项目
      await crowdfundingPlatformV2.createProject("Test Project 2", ethers.utils.parseEther("2"), 86400);
      expect(await crowdfundingPlatformV2.count()).to.equal(2);
    });

    it("should not reset count on upgrades", async function () {
      // 创建一个项目
      await crowdfundingPlatformV2.createProject("Test Project 1", ethers.utils.parseEther("1"), 3600);
      expect(await crowdfundingPlatformV2.count()).to.equal(1);

      // 模拟合约升级
      const CrowdfundingPlatformV2New = await ethers.getContractFactory("CrowdfundingPlatformV2");
      const upgradedContract = await CrowdfundingPlatformV2New.deploy();
      await upgradedContract.initialize(owner.address);

      // 创建新项目，确保 count 没有被重置
      await upgradedContract.createProject("Test Project 2", ethers.utils.parseEther("2"), 86400);
      expect(await upgradedContract.count()).to.equal(2);
    });
  });
});
