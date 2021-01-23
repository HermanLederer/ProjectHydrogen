﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.Interaction.Toolkit;

namespace HydrogenInteractables
{
	public enum HydrogenFilterSocketProblems
	{
		NoProblem,
		FilterMissing,
		FilterInBadCondition
	}

	public class HydrogenFilterSocketInteractor : HydrogenSocketIntractor
	{
		[Header("Filter socket")]
		public HydrogenInteractableType filterType;
		public ParticleSystem troubleParticles;
		public ParticleSystem leakageParticles;
		public AudioSource troubleAudio;
		public bool isOn = true;

		protected override void Awake()
		{
			base.Awake();

			onSelectEntered.AddListener(InsertFilter);
			onSelectExited.AddListener(RemoveFilter);
		}

		new protected void OnTriggerEnter(Collider col)
		{
			HydrogenFilter filter = col.gameObject.GetComponentInParent<HydrogenFilter>();
			if (filter)
				if (filter.type == filterType)
					base.OnTriggerEnter(col);
		}

		new protected void OnTriggerExit(Collider col)
		{
			HydrogenFilter filter = col.gameObject.GetComponentInParent<HydrogenFilter>();
			if (filter)
				if (filter.type == filterType)
					base.OnTriggerExit(col);
		}

		public HydrogenFilterSocketProblems PowerOn(bool silent = false)
		{
			var problem = HydrogenFilterSocketProblems.FilterMissing;

			if (!silent)
			{
				if (selectTarget)
				{
					HydrogenFilter filter = selectTarget.GetComponent<HydrogenFilter>();
					if (filter.isInGoodCondition)
						problem = HydrogenFilterSocketProblems.NoProblem;
					else
						problem = HydrogenFilterSocketProblems.FilterInBadCondition;
				}

				// Problem feedback
				if (problem != HydrogenFilterSocketProblems.NoProblem)
				{
					troubleParticles.Play(true);
					troubleAudio.volume = 1f;
					troubleAudio.Play();
				}
			}

			isOn = true;
			return problem;
		}

		public void PowerOff()
		{
			isOn = false;
			troubleParticles.Stop(true, ParticleSystemStopBehavior.StopEmitting);
			leakageParticles.Stop(true, ParticleSystemStopBehavior.StopEmitting);
			StartCoroutine(StopTroubleAudioCorutine(0.5f));
		}

		public void InsertFilter(XRBaseInteractable interactable)
		{
			leakageParticles.Stop(true, ParticleSystemStopBehavior.StopEmitting);
		}

		public void RemoveFilter(XRBaseInteractable interactable)
		{
			if (isOn)
			{
				leakageParticles.Play(true);
				troubleAudio.volume = 1f;
				troubleAudio.Play();
			}
		}

		IEnumerator StopTroubleAudioCorutine(float duration)
		{
			for (float t = 0f; t < duration; t += Time.deltaTime)
			{
				troubleAudio.volume = Mathf.Lerp(1f, 0f, t / duration);
				yield return new WaitForEndOfFrame();
			}

			troubleAudio.volume = 0f;
			troubleAudio.Stop();
		}
	}
}