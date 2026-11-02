from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PutShiprReposIdPersonasResponse200")


@_attrs_define
class PutShiprReposIdPersonasResponse200:
    """
    Attributes:
        repo_id (str):
        persona_ids (list[str]):
    """

    repo_id: str
    persona_ids: list[str]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        repo_id = self.repo_id

        persona_ids = self.persona_ids

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "repoId": repo_id,
                "personaIds": persona_ids,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        repo_id = d.pop("repoId")

        persona_ids = cast(list[str], d.pop("personaIds"))

        put_shipr_repos_id_personas_response_200 = cls(
            repo_id=repo_id,
            persona_ids=persona_ids,
        )

        put_shipr_repos_id_personas_response_200.additional_properties = d
        return put_shipr_repos_id_personas_response_200

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
