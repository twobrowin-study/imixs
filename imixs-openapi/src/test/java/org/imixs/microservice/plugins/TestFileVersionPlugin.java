package org.imixs.microservice.plugins;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.imixs.workflow.ItemCollection;
import org.imixs.workflow.engine.WorkflowMockEnvironment;
import org.imixs.workflow.FileData;
import org.imixs.workflow.exceptions.AdapterException;
import org.imixs.workflow.exceptions.ModelException;
import org.imixs.workflow.exceptions.PluginException;
import org.junit.Before;
import org.junit.Test;

import junit.framework.Assert;

/**
 * Тестирование плагина управления версиями файлов
 * 
 * @author twobrowin
 */
public class TestFileVersionPlugin {

	private FileVersionPlugin fileVersionPlugin;

	ItemCollection documentActivity;
	ItemCollection documentContext;
	
	WorkflowMockEnvironment workflowMockEnvironment;

	private String contentType   = "application/octet-stream";
	private String contentString = "IyEvYmluL2Jhc2gKcG9kbWFuLWNvbXBvc2UgLXQgaG9zdG5ldCAtZiBkb2NrZXItY29tcG9zZS55bWwgLXAgaW1peHMgLS1kcnktcnVuIHVwID4gaW1peHMtY29tbWFuZHMuc2gK";
	private byte[] content       = contentString.getBytes();

	@Before
	public void setup() throws PluginException, ModelException, AdapterException {
		
		workflowMockEnvironment = new WorkflowMockEnvironment();
		workflowMockEnvironment.setModelPath("/bpmn/TestPlugins.bpmn");
		
		workflowMockEnvironment.setup();

		fileVersionPlugin = new FileVersionPlugin();
		try {
			fileVersionPlugin.init(workflowMockEnvironment.getWorkflowService());
		} catch (PluginException e) {

			e.printStackTrace();
		}

		documentContext=new ItemCollection();
	}


	@Test
	public void fileVersionFirstAppend() throws PluginException, ModelException {
		Map<String, List> fileVersion = new HashMap<>();

		List contentTypeList = new ArrayList<>();
		contentTypeList.add(contentType);

		List contentList = new ArrayList<>();
		contentList.add(content);
		
		fileVersion.put("contentType", contentTypeList);
		fileVersion.put("content",     contentList);

		documentContext.replaceItemValue("fileVersion", fileVersion);
		documentActivity = workflowMockEnvironment.getModel().getEvent(100, 10);

		try {
			fileVersionPlugin.run(documentContext, documentActivity);
		} catch (PluginException e) {

			e.printStackTrace();
			Assert.fail();
		}

		List<Map> fileVersionLogList  = documentContext.getItemValue("txtFileVersionLog");
		String    namLastFileVersion  = documentContext.getItemValueString("namLastFileVersion");
		List      fileVersionAfterRun = documentContext.getItemValue("fileVersion");
		FileData  fileData = documentContext.getFileData(namLastFileVersion);

		Assert.assertEquals(1, fileVersionLogList.size());
		Assert.assertEquals("v1", ((Map) fileVersionLogList.get(0)).get("namversion"));
		Assert.assertEquals("v1", namLastFileVersion);
		Assert.assertEquals("v1", fileData.getName());
		Assert.assertEquals(contentType, fileData.getContentType());
		Assert.assertEquals(content,     fileData.getContent());
		Assert.assertEquals(0, fileVersionAfterRun.size());
	}

}
