from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.ai_processing_provider_kind import AiProcessingProviderKind

if TYPE_CHECKING:
    from ..models.ai_processing_config_set_params import AiProcessingConfigSetParams
    from ..models.ai_processing_job_llm_connection_type_0 import AiProcessingJobLlmConnectionType0


T = TypeVar("T", bound="AiProcessingJobLlm")


@_attrs_define
class AiProcessingJobLlm:
    """
    Attributes:
        config_set_id (None | str): Null = no config set applies
        config_set_name (None | str):
        provider (AiProcessingProviderKind):
        model (str): '' for a local target with no config set: the node uses its own default model
        base_url (None | str): Null for local targets
        connection (AiProcessingJobLlmConnectionType0 | None): Non-secret connection shape only; null for local sets and
            services with no spec
        api_key (None | str): The service's API key for a paid target; null for local
        params (AiProcessingConfigSetParams):
    """

    config_set_id: None | str
    config_set_name: None | str
    provider: AiProcessingProviderKind
    model: str
    base_url: None | str
    connection: AiProcessingJobLlmConnectionType0 | None
    api_key: None | str
    params: AiProcessingConfigSetParams
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.ai_processing_job_llm_connection_type_0 import (
            AiProcessingJobLlmConnectionType0,
        )

        config_set_id: None | str
        config_set_id = self.config_set_id

        config_set_name: None | str
        config_set_name = self.config_set_name

        provider = self.provider.value

        model = self.model

        base_url: None | str
        base_url = self.base_url

        connection: dict[str, Any] | None
        if isinstance(self.connection, AiProcessingJobLlmConnectionType0):
            connection = self.connection.to_dict()
        else:
            connection = self.connection

        api_key: None | str
        api_key = self.api_key

        params = self.params.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "config_set_id": config_set_id,
                "config_set_name": config_set_name,
                "provider": provider,
                "model": model,
                "base_url": base_url,
                "connection": connection,
                "api_key": api_key,
                "params": params,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_config_set_params import (
            AiProcessingConfigSetParams,
        )
        from ..models.ai_processing_job_llm_connection_type_0 import (
            AiProcessingJobLlmConnectionType0,
        )

        d = dict(src_dict)

        def _parse_config_set_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        config_set_id = _parse_config_set_id(d.pop("config_set_id"))

        def _parse_config_set_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        config_set_name = _parse_config_set_name(d.pop("config_set_name"))

        provider = AiProcessingProviderKind(d.pop("provider"))

        model = d.pop("model")

        def _parse_base_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        base_url = _parse_base_url(d.pop("base_url"))

        def _parse_connection(data: object) -> AiProcessingJobLlmConnectionType0 | None:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                connection_type_0 = AiProcessingJobLlmConnectionType0.from_dict(data)

                return connection_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(AiProcessingJobLlmConnectionType0 | None, data)

        connection = _parse_connection(d.pop("connection"))

        def _parse_api_key(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        api_key = _parse_api_key(d.pop("api_key"))

        params = AiProcessingConfigSetParams.from_dict(d.pop("params"))

        ai_processing_job_llm = cls(
            config_set_id=config_set_id,
            config_set_name=config_set_name,
            provider=provider,
            model=model,
            base_url=base_url,
            connection=connection,
            api_key=api_key,
            params=params,
        )

        ai_processing_job_llm.additional_properties = d
        return ai_processing_job_llm

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
