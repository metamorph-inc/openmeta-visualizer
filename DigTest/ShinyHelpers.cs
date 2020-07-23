using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using OpenQA.Selenium.Interactions;
using OpenQA.Selenium.Interactions.Internal;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Drawing;
using System.IO;
using System.Diagnostics;

namespace DigTest
{
    public class ShinySession
    {
        public string all_vars { get; }
        public string original_config { get; }
        public string copied_config { get; }
        public string log_file { get; }
        public string data_file { get; }
        public string download_directory;

        public ShinySession(string config_file)
        {
            all_vars = "";
            original_config = Path.Combine(DigTest.RootPath, config_file);
            // add process id, because sometimes there's an old R process overwriting our config
            copied_config = original_config.Insert(original_config.LastIndexOf(".json"), Process.GetCurrentProcess().Id + "_test");
            log_file = Path.ChangeExtension(copied_config, ".log");
            data_file = Path.ChangeExtension(copied_config.Insert(original_config.LastIndexOf(".json"), "_data"), ".csv");
            download_directory = Path.Combine(DigTest.RootPath, "Downloads");
            EmptyDownloadsDirectory();
        }

        private void EmptyDownloadsDirectory()
        {
            var di = Directory.CreateDirectory(download_directory);
            foreach (var file in di.GetFiles())
            {
                file.Delete();
            }
        }

        public void Cleanup()
        {
            new DirectoryInfo(download_directory).Delete(true);
            File.Delete(copied_config);
            File.Delete(data_file);
        }
    }

    public class ShinySliderInput
    {
        public string id;
        private IWebDriver driver;
        private IWait<IWebDriver> wait;
        private string grid_path;
        private string current_path;
        private double low;
        private double high;
        private double current { get; set; }

        public ShinySliderInput(IWebDriver driver, string id)
        {
            this.driver = driver;
            this.id = id;
            this.wait = new OpenQA.Selenium.Support.UI.WebDriverWait(driver, TimeSpan.FromSeconds(1.0));
            string parent_path = String.Format("//input[@id='{0}']/..", id);
            this.grid_path = parent_path + "/span/span[@class='irs-grid']";
            string low_path = parent_path + "/span/span[@class='irs']/span[@class='irs-min']";
            this.current_path = parent_path + "/span/span[@class='irs']/span[@class='irs-single']";
            string high_path = parent_path + "/span/span[@class='irs']/span[@class='irs-max']";
            this.low = Double.Parse(driver.FindElement(By.XPath(low_path)).GetAttribute("textContent"));
            this.current = Double.Parse(driver.FindElement(By.XPath(current_path)).GetAttribute("textContent"));
            this.high = Double.Parse(driver.FindElement(By.XPath(high_path)).GetAttribute("textContent"));
        }

        public double MoveSliderToValue(double target)
        {
            if(target < low) { target = low; }
            if(target > high) { target = high; }
            Actions builder = new Actions(this.driver);
            var grid = driver.FindElement(By.XPath(this.grid_path));
            var width = grid.Size.Width;
            var old_x = width * (current - low) / (high - low);
            var new_x = width * (target - low) / (high - low);
            builder.MoveToElement(grid, (int)old_x, 0).ClickAndHold();
            builder.MoveByOffset((int)(new_x - old_x), 0).Release().Build().Perform();
            ShinyUtilities.ShinyWait(driver);
            this.current = Double.Parse(driver.FindElement(By.XPath(current_path)).GetAttribute("textContent"));
            return this.current;
        }

        public double GetValue()
        {
            return current;
        }
    }

    public class VisualizerFilterInput
    {
        private IWebDriver driver;
        private WebDriverWait wait;
        private string var;
        private string parent_path;
        private string tooltip_path;
        private string min_path;
        private string max_path;
        private string submit_path;
        private string from_path;
        private string to_path;
        private double low;
        private double high;

        private double from { get; set; }
        private double to { get; set; }

        public VisualizerFilterInput(IWebDriver driver, string variable)
        {
            this.driver = driver;
            this.wait = new OpenQA.Selenium.Support.UI.WebDriverWait(driver, TimeSpan.FromSeconds(1.0));
            this.var = variable;
            this.parent_path = String.Format("//input[@id='filter_{0}']/..", variable);
            this.tooltip_path = String.Format("//div[@id='slider_tooltip_{0}']", variable);
            this.min_path = String.Format("//input[@id='tooltip_min_{0}']", variable);
            this.max_path = String.Format("//input[@id='tooltip_max_{0}']", variable);
            this.submit_path = String.Format("//button[@id='submit_{0}']", variable);
            this.from_path = parent_path + "/span/span[@class='irs']/span[@class='irs-from']";
            this.to_path = parent_path + "/span/span[@class='irs']/span[@class='irs-to']";
            string low_path = parent_path + "/span/span[@class='irs']/span[@class='irs-min']";
            string high_path = parent_path + "/span/span[@class='irs']/span[@class='irs-max']";
            this.low = GetValue(low_path);
            this.from = GetValue(from_path);
            this.to = GetValue(to_path);
            this.high = GetValue(high_path);
        }

        public double EntrySetFrom(double from)
        {
            OpenTooltip();

            if (from < low) { from = low; }
            if (from > to) { from = to; }
            var min = driver.FindElement(By.XPath(min_path));
            min.Clear();
            min.SendKeys(from.ToString());

            driver.FindElement(By.XPath(submit_path)).Click();

            wait.Until(d => GetValue(from_path) == from);
            this.from = from;
            ShinyUtilities.ShinyWait(driver);
            return this.from;
        }

        public double EntrySetTo(double to)
        {
            OpenTooltip();

            if (to > high) { to = high; }
            if (to < from) { to = from; }
            var max = driver.FindElement(By.XPath(max_path));
            max.Clear();
            max.SendKeys(to.ToString());

            driver.FindElement(By.XPath(submit_path)).Click();

            wait.Until(d => GetValue(to_path) == to);
            this.to = to;
            ShinyUtilities.ShinyWait(driver);
            return this.to;
        }

        public string EntrySetFromTo(double from, double to)
        {
            OpenTooltip();

            if (from < low) { from = low; }
            if (from > to) { from = to; }
            var min = driver.FindElement(By.XPath(min_path));
            min.Clear();
            min.SendKeys(from.ToString());

            if (to > high) { to = high; }
            if (to < from) { to = from; }
            var max = driver.FindElement(By.XPath(max_path));
            max.Clear();
            max.SendKeys(to.ToString());

            driver.FindElement(By.XPath(submit_path)).Click();

            wait.Until(d => GetValue(to_path) == to);
            wait.Until(d => GetValue(from_path) == from);
            this.to = to;
            this.from = from;
            ShinyUtilities.ShinyWait(driver);
            return this.from.ToString() + "-" + this.to.ToString();
        }

        private double GetValue(string path)
        {
            int tries = 3;
            while (true)
            {
                try
                {
                    return Double.Parse(driver.FindElement(By.XPath(path)).GetAttribute("textContent"));
                }
                catch (OpenQA.Selenium.StaleElementReferenceException)
                {
                    //Thread.Sleep(100);
                    if (--tries == 0)
                    {
                        throw;
                    }
                }
                catch (OpenQA.Selenium.NoSuchElementException)
                {
                    wait.Until(d => driver.FindElement(By.XPath(path)));
                }
            }
        }

        private void OpenTooltip()
        {
            var parent = driver.FindElement(By.XPath(parent_path));
            Actions double_click_element = new Actions(driver).DoubleClick(parent);
            double_click_element.Build().Perform();
            wait.Until(d => driver.FindElement(By.XPath(tooltip_path)).Displayed);
        }

        public IWebElement GetDiv()
        {
            return driver.FindElement(By.XPath(parent_path));
        }

        public double GetFrom() { return from; }
        public double GetTo() { return to; }
        public string GetFromTo() { return this.from.ToString() + "-" + this.to.ToString(); }
        public double GetMin() { return low; }
        public double GetMax() { return high; }
    }

    public class VisualizerDesignTreeSelector
    {
        private IWebDriver driver;

        public VisualizerDesignTreeSelector(IWebDriver driver)
        {
            this.driver = driver;
        }

        public void ClickByName(string n)
        {
            driver.FindElement(By.XPath("//*[name()='svg' and @id='design_configurations_svg']/*[name()='g']/*[name()='g']/*[name()='text' and text()='" + n + "']/..")).Click();
            ShinyUtilities.ShinyWait(driver);
        }

        public bool SelectedByName(string n)
        {
            var style = driver.FindElement(By.XPath("//*[name()='svg' and @id='design_configurations_svg']/*[name()='g']/*[name()='g']/*[name()='text' and text()='" + n + "']/../*[name()='rect']")).GetAttribute("style");
            return style == "fill: rgb(212, 224, 155);";
        }
    }

    public class ShinySelectInput
    {
        private string id;
        private IWebDriver driver;
        private IWait<IWebDriver> wait;
        private string div;
        private string input;
        private string choices;
        private string selected;

        public ShinySelectInput(IWebDriver driver, string id)
        {
            this.driver = driver;
            this.id = id;
            this.div = string.Format("//select[@id='{0}']/..", id);
            var master_div = this.driver.FindElement(By.XPath(this.div));
            this.input = this.div + "/div[1]/div[1]/input";
            this.choices = this.div + "/select/following::div[1]/div[2]/div[1]/div";
            this.selected = this.div + "/div[1]/div[1]/div[@class='item']";
            this.wait = new OpenQA.Selenium.Support.UI.WebDriverWait(driver, TimeSpan.FromSeconds(11.0));
            try
            {
                this.driver.FindElement(By.XPath(this.choices));
            }
            catch (OpenQA.Selenium.NoSuchElementException)
            {
                // Force the choices to appear.
                master_div.Click();
                ShinyUtilities.ShinyWait(driver);
                this.driver.FindElement(By.XPath(this.input)).SendKeys(Keys.Escape);
                ShinyUtilities.ShinyWait(driver);
            }
            if (this.driver.FindElement(By.XPath(this.choices)).GetAttribute("data-value") == null)
            {
                this.choices = string.Format("//select[@id='{0}']/following::div[1]/div[2]/div[1]/div/div[@class='option selected' or @class='option']", id);
                this.selected = string.Format("//select[@id='{0}']/following::div[1]/div[1]/div[@class='item']", id);
            }
        }

        public string GetCurrentSelection()
        {
            this.wait.Until(ExpectedConditions.ElementExists(By.XPath(this.selected)));
            return this.driver.FindElement(By.XPath(this.selected)).GetAttribute("data-value");
        }

        public IWebElement GetDiv()
        {
            return this.driver.FindElement(By.XPath(this.div));
        }

        private IEnumerable<IWebElement> GetAllChoiceDivs()
        {
            return this.driver.FindElements(By.XPath(this.choices));
        }

        public IEnumerable<string> GetAllChoices()
        {
            // TODO(tthomas): Find a way to turn the retry logic into a function.
            IEnumerable<string> choices;
            int tries = 3;
            while (true)
            {
                try
                {
                    var choices_divs = this.driver.FindElements(By.XPath(this.choices));
                    var choices_list = new List<string>();
                    for(var i = 0; i < choices_divs.Count(); i++)
                    {
                        choices_list.Add(choices_divs[i].GetAttribute("data-value"));
                    }
                    choices = choices_list.AsEnumerable();
                    break;
                }
                catch (OpenQA.Selenium.NoSuchElementException)
                {
                    ShinyUtilities.ShinyWait(driver);
                    if (--tries == 0)
                    {
                        throw;
                    }
                }
                catch (OpenQA.Selenium.StaleElementReferenceException)
                {
                    ShinyUtilities.ShinyWait(driver);
                    if (--tries == 0)
                    {
                        throw;
                    }
                }
            }
            return choices;
        }

        public void SetCurrentSelectionClicked(string v)
        {
            var master_div = driver.FindElement(By.XPath(div));
            master_div.Click();
            ShinyUtilities.ShinyWait(driver);
            IEnumerable<IWebElement> choices = null;
            IEnumerable<IWebElement> to_select = null;
            string[] values = null;
            for (int retry = 0; retry < 5; retry++)
            {
                choices = this.GetAllChoiceDivs();
                to_select = from choice in choices
                            where choice.GetAttribute("data-value") == v
                            select choice;

                values = to_select.Select(x => x.Text).ToArray();
                if (values.Length > 0)
                {
                    break;
                }
                ShinyUtilities.ShinyWait(driver);
            }
            this.wait.Until(driver1 => to_select.First().Displayed);
            to_select.First().Click();
        }

        public void SetCurrentSelectionTyped(string v)
        {
            this.driver.FindElement(By.XPath(div)).Click();
            var input = driver.FindElement(By.XPath(this.input));
            input.SendKeys(Keys.Backspace);
            input.SendKeys(v);
            input.SendKeys(Keys.Enter);
        }
    }

    public class ShinySelectMultipleInput
    {
        private IWebDriver driver;
        private string id;
        private string div;
        private string input;
        private string choices;
        private string selected;
        private bool selectize;
        private WebDriverWait wait;

        public ShinySelectMultipleInput(IWebDriver driver, string id, bool selectize = true)
        {
            this.driver = driver;
            this.wait = new OpenQA.Selenium.Support.UI.WebDriverWait(driver, TimeSpan.FromSeconds(11.0));
            this.id = id;
            this.selectize = selectize;
            this.div = string.Format("//select[@id='{0}']/..", id);
            if (selectize)
            {
                this.input = this.div + "/div[1]/div[1]/input";
                this.choices = this.div + "/div[1]/div[2]/div/div";
                this.selected = this.div + "/div[1]/div[1]/div[@class='item']";
                try
                {
                    this.driver.FindElement(By.XPath(this.choices));
                }
                catch (OpenQA.Selenium.NoSuchElementException)
                {
                    // Force the choices to appear.
                    this.driver.FindElement(By.XPath(this.div)).Click();
                    ShinyUtilities.ShinyWait(driver);
                    this.driver.FindElement(By.XPath(this.input)).SendKeys(Keys.Escape);
                    ShinyUtilities.ShinyWait(driver);
                }
                if (this.driver.FindElement(By.XPath(this.choices)).GetAttribute("data-value") == null)
                {
                    this.choices = string.Format("//select[@id='{0}']/following::div[1]/div[2]/div[1]/div/div[@class='option selected' or @class='option']", id);
                    this.selected = string.Format("//select[@id='{0}']/following::div[1]/div[1]/div[@class='item']", id);
                }
            }
            else
            {
                this.input = null;
                this.choices = this.div + "/select/option";
                this.selected = this.div + "/select/option[@selected]";
            }
        }

        public string GetCurrentSelection()
        {
            IEnumerable<string> selected = null;
            var attr_name = selectize ? "data-value" : "value";
            try
            {
                selected = from selected_div in this.driver.FindElements(By.XPath(this.selected))
                           select selected_div.GetAttribute(attr_name);
                return string.Join(", ",selected.ToArray());
            }
            catch (OpenQA.Selenium.NoSuchElementException)
            {
                return null;
            }
        }

        public IWebElement GetDiv()
        {
            return driver.FindElement(By.XPath(div));
        }

        private IEnumerable<IWebElement> GetAllChoiceDivs()
        {
            return driver.FindElements(By.XPath(choices));
        }

        public IEnumerable<string> GetRemainingChoices()
        {
            // TODO(tthomas): Find a way to turn the retry logic into a function.
            IEnumerable<string> choices;
            ShinyUtilities.ShinyWait(driver);
            int tries = 3;
            while (true)
            {
                try
                {
                    choices = from choice_div in driver.FindElements(By.XPath(this.choices))
                              select choice_div.GetAttribute("data-value");
                    break;
                }
                catch (OpenQA.Selenium.NoSuchElementException)
                {
                    ShinyUtilities.ShinyWait(driver);
                    if (--tries == 0)
                    {
                        throw;
                    }
                }
            }
            return choices;
        }

        public void AppendSelection(string v)
        {
            var input = this.driver.FindElement(By.XPath(this.input));
            input.SendKeys(Keys.ArrowRight);
            input.SendKeys(v);
            input.SendKeys(Keys.Enter);
            input.SendKeys(Keys.Escape);
        }

        public void ToggleItem(string v, bool? select = null)
        {
            if(!selectize)
            {
                var path = this.div + "/select/option[@value='" + v + "']";
                if (driver.FindElement(By.XPath(path)).Displayed)
                {
                    if (select != null)
                    {
                        var selectElement = driver.FindElement(By.XPath(this.div + "/select"));
                        var isSelected = (Int64)((IJavaScriptExecutor)driver).ExecuteScript(
                            "return [].slice.call(arguments[0].selectedOptions).filter(function (option) { return option.value === arguments[1] }).length", new object[] { selectElement, v });
                        if ((isSelected == 1) == select)
                        {
                            // already selected/deselected
                            return;
                        }
                    }

                    //var original_state = driver.FindElement(By.XPath(path)).GetAttribute("selected");
                    driver.FindElement(By.XPath(path)).Click();
                    ShinyUtilities.ShinyWait(driver);
                    //var expected_new_state = original_state == "true" ? null : "true";
                    //wait.Until(d => driver.FindElement(By.XPath(path)).GetAttribute("selected") == expected_new_state);
                }
            }
        }
    }

    public class ShinyCheckboxInput
    {
        private IWebDriver driver;
        private WebDriverWait wait;
        private string id;
        private bool state;

        public ShinyCheckboxInput(IWebDriver driver, string id)
        {
            this.driver = driver;
            this.wait = new OpenQA.Selenium.Support.UI.WebDriverWait(driver, TimeSpan.FromMilliseconds(200.0));
            this.id = id;
            this.state = GetStartState();
        }

        public bool ToggleState()
        {
            driver.FindElement(By.Id(id)).Click();
            ShinyUtilities.ShinyWait(driver);
            return state = !state;
        }

        public bool GetStartState()
        {
            return "true" == driver.FindElement(By.Id(id)).GetAttribute("data-shinyjs-resettable-value");
        }

        public bool GetState()
        {
            return state;
        }
    }

    public class ShinyPlot
    {
        private IWebDriver driver;
        private WebDriverWait wait;
        private string id;
        private string img_str;
        private string img_path;
        private string img_str_change;
        private string img_str_reload;

        public ShinyPlot(IWebDriver driver, string id)
        {
            this.driver = driver;
            this.wait = new OpenQA.Selenium.Support.UI.WebDriverWait(driver, TimeSpan.FromSeconds(10.0));
            this.wait.IgnoreExceptionTypes(typeof(NoSuchElementException));
            this.id = id;
            this.img_path = String.Format("//div[@id='{0}']/img", id);
            ReloadImage();
            img_str_change = img_str;
        }

        private byte[] GetData()
        {
            string trim = img_str.Substring("data:image/png;base64,".Length);
            return Convert.FromBase64String(trim);
        }

        private void ReloadImage()
        {
            IWebElement img_elem = null;
            wait.Until(d => img_elem = driver.FindElement(By.XPath(this.img_path)));
            img_str = img_elem.GetAttribute("src");
        }

        public IWebElement GetElement()
        {
            return driver.FindElement(By.Id(id));
        }

        public bool ImageHasChanged()
        {
            ReloadImage();
            var changed = (img_str_change != img_str);
            img_str_change = img_str;
            return changed;
        }

        private bool DoneReloading()
        {
            ReloadImage();
            bool same = img_str_reload == img_str;
            bool recalculating = driver.FindElement(By.Id(id)).GetAttribute("class").Split().Contains("recalculating");
            return !same && !recalculating;
        }

        public void WaitUntilImageRefreshes()
        {
            img_str_reload = img_str;
            wait.Until(a => DoneReloading());
        }

        public bool ImageIncludesColor(Color color)
        {
            ReloadImage();
            using (MemoryStream stream = new MemoryStream(GetData()))
            {
                var image = new Bitmap(stream);
                // Loop through the pixels.
                for (int y = 0; y < image.Height; y++)
                {
                    for (int x = 0; x < image.Width; x++)
                    {
                        if (image.GetPixel(x, y) == color) return true;
                    }
                }
                return false;
            }
        }

        public int ImageColorCount(Color color)
        {
            ReloadImage();
            using (MemoryStream stream = new MemoryStream(GetData()))
            {
                var image = new Bitmap(stream);
                // Loop through the pixels.
                int matches = 0;
                for (int y = 0; y < image.Height; y++)
                {
                    for (int x = 0; x < image.Width; x++)
                    {
                        if (image.GetPixel(x, y) == color) matches++;
                    }
                }
                return matches;
            }
        }

        public Dictionary<Color, int> ImageStats()
        {
            ReloadImage();
            using (MemoryStream stream = new MemoryStream(GetData()))
            {
                var image = new Bitmap(stream);
                // Loop through the pixels.
                var matches = new Dictionary<Color, int>();
                for (int y = 0; y < image.Height; y++)
                {
                    for (int x = 0; x < image.Width; x++)
                    {
                        var color = image.GetPixel(x, y);
                        if (matches.ContainsKey(color))
                        {
                            matches[color] += 1;
                        }
                        else
                        {
                            matches.Add(color, 1);
                        }
                    }
                }
                return matches;
            }
        }
    }

    public class VisualizerFilterStats
    {
        private IWebDriver driver;

        public VisualizerFilterStats(IWebDriver driver)
        {
            this.driver = driver;
        }

        public int GetCurrentPoints()
        {
            return Int32.Parse(driver.FindElement(By.Id("filters_stats")).GetAttribute("textContent").Split()[2]);
        }

        public int GetTotalPoints()
        {
            return Int32.Parse(driver.FindElement(By.Id("filters_stats")).GetAttribute("textContent").Split()[4]);
        }

        public double GetPercentage()
        {
            var test = driver.FindElement(By.Id("filters_stats")).GetAttribute("textContent").Split();
            return Double.Parse(driver.FindElement(By.Id("filters_stats")).GetAttribute("textContent").Split()[7].Split('%')[0]) / 100;
        }
    }

    public class ShinyUtilities
    {
        public static void OpenTabPanel(IWebDriver driver, string tabset_id, string tab_name)
        {
            string link_path = String.Format("//ul[@id='{0}']/li/a[@data-value='{1}']",
                                             tabset_id, tab_name);
            string content_path = String.Format("//ul[@id='{0}']/../div/div[@data-value='{1}']",
                                                tabset_id, tab_name);
            if (!driver.FindElement(By.XPath(content_path)).GetAttribute("class").Split().Contains("active"))
            {
                if (!driver.FindElement(By.XPath(link_path)).Displayed)
                {
                    ScrollToElement(driver, driver.FindElement(By.XPath(link_path)));
                }
                driver.FindElement(By.XPath(link_path)).Click();
                WebDriverWait wait = new OpenQA.Selenium.Support.UI.WebDriverWait(driver, TimeSpan.FromSeconds(5.0));
                IWebElement content = driver.FindElement(By.XPath(content_path));
                wait.Until(d => content.GetAttribute("class").Split().Contains("active"));
            }
        }

        public static void OpenCollapsePanel(IWebDriver driver, string collapse_id, string panel_name)
        {
            string base_path = String.Format("//div[@id='{0}']/div[@value='{1}']",
                                             collapse_id, panel_name);
            string link_path = base_path + "/div[@class='panel-heading']/h4/a";
            string content_path = base_path + "/div[2]";
            string class_attribute = driver.FindElement(By.XPath(content_path)).GetAttribute("class");
            if (!class_attribute.Split().Contains("in"))
            {
                if (!driver.FindElement(By.XPath(link_path)).Displayed)
                {
                    ScrollToElement(driver, driver.FindElement(By.XPath(link_path)));
                }
                driver.FindElement(By.XPath(link_path)).Click();
                WebDriverWait wait = new OpenQA.Selenium.Support.UI.WebDriverWait(driver, TimeSpan.FromSeconds(5.0));
                IWebElement content = driver.FindElement(By.XPath(content_path));
                wait.Until(d => content.GetAttribute("class").Split().Contains("in"));
                wait.Until(d => content.GetAttribute("style") == "");
            }
        }

        public static void ScrollToElement(IWebDriver driver, IWebElement elem)
        {
            string jsToBeExecuted = string.Format("window.scroll(0, {0});", elem.Location.Y);
            ((IJavaScriptExecutor)driver).ExecuteScript(jsToBeExecuted);
        }

        public static void ScrollToElementID(IWebDriver driver, string id)
        {
            ScrollToElement(driver, driver.FindElement(By.Id(id)));
        }

        public static void ClickIDWithScroll(IWebDriver driver, string id)
        {
            IWebElement elem = driver.FindElement(By.Id(id));
            try
            {
                elem.Click();
            }
            catch (System.InvalidOperationException)
            {
                ScrollToElement(driver, elem);
                elem.Click();
            }
        }

        public static void ScrollToTop(IWebDriver driver)
        {
            ((IJavaScriptExecutor)driver).ExecuteScript("window.scroll(0, 0);");
        }

        public static bool WaitUntilDocumentReady(IWebDriver driver)
        {
            IWait<IWebDriver> wait10 = new OpenQA.Selenium.Support.UI.WebDriverWait(driver, TimeSpan.FromSeconds(10.0));
            return wait10.Until(driver1 => ((IJavaScriptExecutor)driver).ExecuteScript("return document.readyState").Equals("complete"));
        }

        public static void InstallShinyWait(IWebDriver driver)
        {
            ((IJavaScriptExecutor)driver).ExecuteScript("document.body.insertAdjacentHTML('afterbegin', '<div id=\"test-progress\" style=\"position: absolute; left:  50%;\">test-init</div>');");
            ((IJavaScriptExecutor)driver).ExecuteScript("Shiny.addCustomMessageHandler('server-test-progress', function(message) { document.getElementById('test-progress').innerText = message })");
        }

        public static void ShinyWait(IWebDriver driver)
        {
            // this waits for an injected input change to be echoed back to the client by the shiny server
            var unique_string = Guid.NewGuid().ToString("");
            ((IJavaScriptExecutor)driver).ExecuteScript("Shiny.onInputChange('test_progress', arguments[0])", new object[] { unique_string });

            IWait<IWebDriver> wait = new OpenQA.Selenium.Support.UI.WebDriverWait(driver, TimeSpan.FromSeconds(10.0));
            try
            {
                wait.Until(ExpectedConditions.TextToBePresentInElement(driver.FindElement(By.Id("test-progress")), unique_string));
            }
            catch (NoSuchElementException e)
            {
                if (e.Message.Contains("test-output"))
                {
                    throw new NoSuchElementException("Cannot find test-progress element. Did you call InstallShinyWait?", e);
                }
                throw;
            }
        }

        public static string ReadVerbatimText(IWebDriver driver, string id)
        {
            return driver.FindElement(By.Id(id)).GetAttribute("textContent");
        }
    }
}
