from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.ai_processing_config_set_params import AiProcessingConfigSetParams


T = TypeVar("T", bound="AiProcessingConfigSetInput")


@_attrs_define
class AiProcessingConfigSetInput:
    """
    Attributes:
        name (str): Unique across config sets
        model (str): Required; for a service, one of its known models when it lists any
        description (None | str | Unset):
        service_id (None | str | Unset): A personas service id; null or absent = the node's local LLM
        params (AiProcessingConfigSetParams | Unset):
    """

    name: str
    model: str
    description: None | str | Unset = UNSET
    service_id: None | str | Unset = UNSET
    params: AiProcessingConfigSetParams | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        model = self.model

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        service_id: None | str | Unset
        if isinstance(self.service_id, Unset):
            service_id = UNSET
        else:
            service_id = self.service_id

        params: dict[str, Any] | Unset = UNSET
        if not isinstance(self.params, Unset):
            params = self.params.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "model": model,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if service_id is not UNSET:
            field_dict["service_id"] = service_id
        if params is not UNSET:
            field_dict["params"] = params

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_config_set_params import (
            AiProcessingConfigSetParams,
        )

        d = dict(src_dict)
        name = d.pop("name")

        model = d.pop("model")

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        def _parse_service_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        service_id = _parse_service_id(d.pop("service_id", UNSET))

        _params = d.pop("params", UNSET)
        params: AiProcessingConfigSetParams | Unset
        if isinstance(_params, Unset):
            params = UNSET
        else:
            params = AiProcessingConfigSetParams.from_dict(_params)

        ai_processing_config_set_input = cls(
            name=name,
            model=model,
            description=description,
            service_id=service_id,
            params=params,
        )

        ai_processing_config_set_input.additional_properties = d
        return ai_processing_config_set_input

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
